# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoxRequest do
  subject(:box) { described_class.new(params) }

  let(:params) { { 'width' => '5', 'height' => '3', 'depth' => '4', 'thickness' => '0.245', 'units' => 'in' } }

  describe '.defaults' do
    it 'reports what laser-cutter assumes for each unit' do
      expect(described_class.defaults).to include(
        'in' => include('kerf' => 0.026, 'margin' => 0.125),
        'mm' => include('kerf' => 0.66)
      )
    end
  end

  describe '.page_sizes' do
    it 'lists the page sizes in both units' do
      expect(described_class.page_sizes['in']).to include(['LETTER', 8.5, 11.0])
      expect(described_class.page_sizes['mm']).to include(['A4', 210.0, 297.0])
    end
  end

  describe '#valid?' do
    it { is_expected.to be_valid }

    it 'accepts a decimal comma' do
      expect(described_class.new(params.merge('thickness' => '0,245'))).to be_valid
    end

    it 'names every dimension that is missing or zero' do
      box = described_class.new(params.merge('width' => '', 'depth' => '0'))
      expect(box).not_to be_valid
      expect(box.errors).to eq ['Width needs a number above zero.', 'Depth needs a number above zero.']
    end

    it 'rejects material thicker than the shortest side' do
      box = described_class.new(params.merge('thickness' => '3'))
      expect(box).not_to be_valid
      expect(box.errors).to eq ['Thickness has to be smaller than the shortest side of the box.']
    end

    it 'rejects an optional setting that is not a number' do
      box = described_class.new(params.merge('notch' => 'wide', 'kerf' => '-1'))
      expect(box).not_to be_valid
      expect(box.errors).to eq ['Notch length needs a number, or leave it blank.', 'Kerf needs a number, or leave it blank.']
    end

    it 'rejects a page size laser-cutter does not know' do
      box = described_class.new(params.merge('page_size' => 'POSTCARD'))
      expect(box).not_to be_valid
      expect(box.errors).to eq ['POSTCARD is not a page size we know.']
    end

    context 'with a lid' do
      let(:params) { super().merge('lid' => 'plain') }

      it 'is refused while the installed laser-cutter cannot draw lids' do
        allow(described_class).to receive(:lids_supported?).and_return(false)
        expect(box).not_to be_valid
        expect(box.errors).to eq ['This lid needs laser-cutter 2.0.1 or newer.']
      end

      it 'is accepted once it can' do
        allow(described_class).to receive(:lids_supported?).and_return(true)
        expect(box).to be_valid
      end
    end
  end

  describe 'notch length' do
    # The shortest side is 3 in, so a notch may be 0.2 to 1 in.
    { '0.2' => true, '1' => true, '0.19' => false, '1.01' => false }.each do |notch, allowed|
      it "#{allowed ? 'accepts' : 'refuses'} #{notch} in" do
        expect(described_class.new(params.merge('notch' => notch)).valid?).to be allowed
      end
    end

    it 'says what the range is' do
      box = described_class.new(params.merge('notch' => '2'))
      box.valid?
      expect(box.errors).to eq ['Notch length has to be between 0.2 and 1 in, or blank.']
    end

    it 'works in millimetres, from 5 mm' do
      mm = { 'width' => '300', 'height' => '90', 'depth' => '120', 'thickness' => '3', 'units' => 'mm' }
      expect(described_class.new(mm.merge('notch' => '30'))).to be_valid
      expect(described_class.new(mm.merge('notch' => '5'))).to be_valid
      expect(described_class.new(mm.merge('notch' => '4.9'))).not_to be_valid
      expect(described_class.new(mm.merge('notch' => '31'))).not_to be_valid
    end

    # A third of 0.9 in is 0.3, and half that is below the usual 0.2: the range becomes 0.15 to 0.3.
    it 'lets a small box go below the usual minimum, down to half the maximum' do
      small = params.merge('width' => '1', 'height' => '0.9', 'depth' => '1', 'thickness' => '0.1')
      { '0.3' => true, '0.15' => true, '0.2' => true, '0.14' => false, '0.31' => false, '0.4' => false }.each do |notch, allowed|
        expect(described_class.new(small.merge('notch' => notch)).valid?).to be(allowed), "notch #{notch}"
      end
    end

    # The page shows both limits rounded down, so those must be accepted here.
    context 'when a third of the side is not a round number' do
      let(:cube) { params.merge('width' => '1', 'height' => '1', 'depth' => '1', 'thickness' => '0.1') }

      it 'accepts the rounded limits the page shows' do
        expect(described_class.new(cube.merge('notch' => '0.33'))).to be_valid
        expect(described_class.new(cube.merge('notch' => '0.16'))).to be_valid
      end

      it 'names those limits when it refuses' do
        box = described_class.new(cube.merge('notch' => '0.34'))
        box.valid?
        expect(box.errors).to eq ['Notch length has to be between 0.16 and 0.33 in, or blank.']
      end

      it 'rounds millimetres to a tenth' do
        mm = { 'width' => '25', 'height' => '25', 'depth' => '25', 'thickness' => '3', 'units' => 'mm' }
        expect(described_class.new(mm.merge('notch' => '8.3'))).to be_valid
        expect(described_class.new(mm.merge('notch' => '8.4'))).not_to be_valid
      end
    end

    it 'refuses zero' do
      box = described_class.new(params.merge('notch' => '0'))
      box.valid?
      expect(box.errors).to eq ['Notch length has to be above zero, or leave it blank.']
    end
  end

  describe 'size limits' do
    it 'refuses more than 150 notches along the longest side' do
      box = described_class.new(params.merge('width' => '100', 'thickness' => '0.05'))
      box.valid?
      expect(box.errors).to eq ['That is 669 notches along the longest side, and 150 is the most we draw. Use thicker material or a longer notch.']
    end

    it 'counts with the notch length when one is given' do
      thin = params.merge('width' => '60', 'height' => '6', 'depth' => '6', 'thickness' => '0.05')
      expect(described_class.new(thin)).not_to be_valid
      expect(described_class.new(thin.merge('notch' => '2'))).to be_valid
    end

    it 'refuses numbers that are not finite' do
      box = described_class.new(params.merge('width' => '1e999', 'height' => '1e999', 'depth' => '1e999'))
      box.valid?
      expect(box.errors).to eq(%w[Width Height Depth].map { |name| "#{name} needs a number above zero." })
    end

    it 'refuses a zero stroke, which laser-cutter cannot draw' do
      box = described_class.new(params.merge('stroke' => '0'))
      box.valid?
      expect(box.errors).to eq ['Stroke has to be above zero, or leave it blank.']
    end

    it 'refuses a setting larger than the box' do
      box = described_class.new(params.merge('padding' => '1e300', 'kerf' => '6'))
      box.valid?
      expect(box.errors).to eq ['Kerf cannot be larger than the box.', 'Padding cannot be larger than the box.']
    end

    { 'units' => 'MM', 'lid' => 'dome', 'page_layout' => 'sideways' }.each do |key, value|
      it "refuses #{key}=#{value} instead of guessing" do
        box = described_class.new(params.merge(key => value))
        expect(box).not_to be_valid
        expect(box.errors.first).to start_with("#{value} is not one of ")
      end
    end

    it 'allows zero kerf, margin and padding' do
      expect(described_class.new(params.merge('kerf' => '0', 'margin' => '0', 'padding' => '0'))).to be_valid
    end
  end

  describe '.lids_supported?' do
    it 'is off for a laser-cutter that only draws the full lid' do
      hide_const('Laser::Cutter::Box::LIDS')
      expect(described_class.lids_supported?).to be false
    end

    it 'is on once laser-cutter lists its lids' do
      stub_const('Laser::Cutter::Box::LIDS', %i[full back plain])
      expect(described_class.lids_supported?).to be true
    end
  end

  describe '#units and #lid' do
    it 'fall back to inches and the full lid for anything unknown' do
      box = described_class.new(params.merge('units' => 'furlongs', 'lid' => 'dome'))
      expect(box.units).to eq 'in'
      expect(box.lid).to eq 'full'
    end
  end

  describe '#filename' do
    it 'says which box is inside' do
      expect(box.filename('pdf')).to eq 'makeabox-5x3x4in-0.245t.pdf'
    end

    it 'keeps the unit' do
      expect(described_class.new(params.merge('units' => 'mm', 'width' => '127.5')).filename('svg')).to eq 'makeabox-127.5x3x4mm-0.245t.svg'
    end
  end

  describe '#configuration' do
    subject(:config) { box.configuration('/tmp/box.pdf') }

    it 'hands laser-cutter the dimensions as numbers' do
      expect(config).to include(width: 5.0, height: 3.0, depth: 4.0, thickness: 0.245, units: 'in', file: '/tmp/box.pdf')
    end

    it 'leaves blank settings to the defaults of the gem' do
      expect(config).to include(kerf: 0.026, notch: 0.735, page_layout: 'portrait', metadata: true)
    end

    it 'passes the optional settings through' do
      box = described_class.new(params.merge('notch' => '0.5', 'page_size' => 'A4', 'page_layout' => 'landscape', 'metadata' => '0'))
      expect(box.configuration('/tmp/box.pdf')).to include(notch: 0.5, page_size: 'A4', page_layout: 'landscape', metadata: false)
    end

    it 'falls back to the full lid when laser-cutter cannot draw another' do
      allow(described_class).to receive(:lids_supported?).and_return(false)
      expect(described_class.new(params.merge('lid' => 'plain')).configuration('/tmp/box.pdf')).to include(lid: 'full')
    end

    it 'passes the lid on' do
      expect(described_class.new(params.merge('lid' => 'plain')).configuration('/tmp/box.pdf')).to include(lid: 'plain')
    end

    it 'asks for the full lid by default' do
      expect(described_class.new(params.merge('lid' => 'full')).configuration('/tmp/box.pdf')).to include(lid: 'full')
    end
  end

  describe '#render' do
    it 'returns a PDF' do
      expect(box.render('pdf')).to start_with('%PDF-')
    end

    it 'returns an SVG and counts every line as it is drawn' do
      counts = []
      svg = box.render('svg') { |done, total| counts << [done, total] }

      expect(svg).to include('<svg', '<line')
      expect(counts.first).to eq [1, 376]
      expect(counts.last).to eq [376, 376]
    end

    { 'full' => 376, 'back' => 284, 'plain' => 248 }.each do |lid, lines|
      it "draws the #{lid} lid in #{lines} lines" do
        total = nil
        described_class.new(params.merge('lid' => lid)).render('svg') { |_, count| total = count }
        expect(total).to eq lines
      end
    end

    it 'leaves no file behind' do
      before = Dir.glob(File.join(Dir.tmpdir, 'makeabox*'))
      box.render('svg')
      expect(Dir.glob(File.join(Dir.tmpdir, 'makeabox*'))).to eq before
    end
  end
end
