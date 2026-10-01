# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Boxes' do
  let(:box) { { width: 5, height: 3, depth: 4, thickness: 0.245, units: 'in' } }

  # @return [Array<Array(String, Hash)>] the server-sent events as [name, data]
  def events
    response.body.split("\n\n").map do |chunk|
      [chunk[/^event: (.+)$/, 1], JSON.parse(chunk[/^data: (.+)$/m, 1])]
    end
  end

  describe 'GET /box/stream' do
    it 'reports progress, then sends the drawing' do
      get '/box/stream', params: { box: box }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'text/event-stream'
      expect(events.map(&:first).uniq).to eq %w[progress drawn]
      expect(events.last.last).to include('filename' => 'makeabox-5x3x4in-0.245t.svg', 'svg' => a_string_including('<svg'))
    end

    it 'counts the lines from the first step to the last' do
      get '/box/stream', params: { box: box }

      expect(events.first.last).to eq('done' => 8, 'total' => 376)
      expect(events[-2].last).to eq('done' => 376, 'total' => 376)
    end

    it 'draws a lid that lifts off' do
      get '/box/stream', params: { box: box.merge(lid: 'back') }

      expect(events[-2].last).to eq('done' => 284, 'total' => 284)
      expect(events.last.first).to eq 'drawn'
    end

    [{}, { lid: 'plain' }, { width: 20, height: 20, depth: 20, thickness: 0.125 }].each do |change|
      it "never sends more than #{BoxesController::PROGRESS_EVENTS + 1} progress events (#{change.presence || 'default box'})" do
        get '/box/stream', params: { box: box.merge(change) }

        expect(events.count { |name, _| name == 'progress' }).to be_between(2, BoxesController::PROGRESS_EVENTS + 1)
      end
    end

    it 'refuses a box with more notches than anyone can cut, before drawing it' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise('must not be drawn') # rubocop:disable RSpec/AnyInstance

      get '/box/stream', params: { box: box.merge(width: 1000, height: 1000, depth: 1000, thickness: 0.01) }

      expect(events.map(&:first)).to eq ['failed']
      expect(events.last.last['message']).to include('150 is the most we draw')
    end

    it 'treats a box that is not a set of fields as an empty one' do
      get '/box/stream', params: { box: 'abc' }

      expect(events).to eq [['failed', { 'message' => %w[Width Height Depth Thickness].map { |name| "#{name} needs a number above zero." }.join(' ') }]]
    end

    it 'says what is wrong with the box' do
      get '/box/stream', params: { box: box.merge(width: 0) }

      expect(events).to eq [['failed', { 'message' => 'Width needs a number above zero.' }]]
    end

    it 'reports a drawing laser-cutter gives up on' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise(Laser::Cutter::Error, 'no such notch') # rubocop:disable RSpec/AnyInstance

      get '/box/stream', params: { box: box }

      expect(events).to eq [['failed', { 'message' => 'laser-cutter could not draw this box: no such notch' }]]
    end

    it 'gives up on a drawing that takes too long' do
      stub_const('BoxesController::RENDER_SECONDS', 0.05)
      allow_any_instance_of(BoxRequest).to receive(:render) { sleep 1 } # rubocop:disable RSpec/AnyInstance

      get '/box/stream', params: { box: box }

      expect(events).to eq [['failed', { 'message' => 'That box took more than 0.05 seconds to draw. Try thicker material or a longer notch.' }]]
    end

    # An IOError from the renderer is not a reader hanging up, and an
    # ArgumentError is not laser-cutter refusing the box.
    [NoMethodError, IOError, ArgumentError, FloatDomainError].each do |error|
      it "owns up to a #{error} of ours instead of going quiet" do
        allow_any_instance_of(BoxRequest).to receive(:render).and_raise(error, 'oops') # rubocop:disable RSpec/AnyInstance
        expect(Rails.logger).to receive(:error).with(a_string_including("#{error}: oops"))
        expect(Rails.error).to receive(:report).with(an_instance_of(error), handled: true)

        get '/box/stream', params: { box: box }

        expect(events).to eq [['failed', { 'message' => 'Something went wrong on our side while drawing this box. It has been logged.' }]]
      end
    end

    it 'refuses units it does not know instead of drawing in inches' do
      get '/box/stream', params: { box: box.merge(units: 'MM') }

      expect(events).to eq [['failed', { 'message' => 'MM is not one of in, mm.' }]]
    end

    it 'survives a client that went away' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise(ActionController::Live::ClientDisconnected) # rubocop:disable RSpec/AnyInstance

      expect { get '/box/stream', params: { box: box } }.not_to raise_error
    end

    it 'ignores parameters it does not know' do
      get '/box/stream', params: { box: box.merge(file: '/etc/passwd') }

      expect(events.last.first).to eq 'drawn'
    end
  end

  describe 'GET /box/download' do
    it 'sends the PDF as a file' do
      get '/box/download.pdf', params: { box: box }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'application/pdf'
      expect(response.headers['Content-Disposition']).to include('attachment', 'makeabox-5x3x4in-0.245t.pdf')
      expect(response.body).to start_with('%PDF-')
    end

    it 'counts the box it sends' do
      expect { get '/box/download.pdf', params: { box: box } }.to change(Makeabox::BoxCounter, :total).by(1)
    end

    it 'does not count a box it refuses' do
      expect { get '/box/download.pdf', params: { box: box.merge(width: 0) } }.not_to change(Makeabox::BoxCounter, :total)
    end

    it 'sends the SVG as a file' do
      get '/box/download.svg', params: { box: box }

      expect(response.media_type).to eq 'image/svg+xml'
      expect(response.body).to include('<svg')
    end

    it 'has nothing for a format it does not make' do
      get '/box/download.dxf', params: { box: box }

      expect(response).to have_http_status(:not_found)
    end

    it 'gives up on a drawing that takes too long' do
      stub_const('BoxesController::RENDER_SECONDS', 0.05)
      allow_any_instance_of(BoxRequest).to receive(:render) { sleep 1 } # rubocop:disable RSpec/AnyInstance

      get '/box/download.pdf', params: { box: box }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to start_with('That box took more than 0.05 seconds')
    end

    it 'defaults to the PDF' do
      get '/box/download', params: { box: box }

      expect(response.media_type).to eq 'application/pdf'
    end

    it 'says what is wrong with the box' do
      get '/box/download.pdf', params: { box: box.merge(thickness: 9) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to eq 'Thickness has to be smaller than the shortest side of the box.'
    end

    # What a browser without JavaScript submits: every field, the blank ones included.
    it 'sends the PDF for the plain form, blank fields and all' do
      blank = { notch: '', kerf: '', margin: '', padding: '', stroke: '', page_size: '', page_layout: 'portrait', metadata: '1', lid: 'full' }
      get '/box/download.pdf', params: { box: box.merge(blank) }

      expect(response).to have_http_status(:ok)
      expect(response.body).to start_with('%PDF-')
    end

    {
      'a zero stroke' => [{ stroke: 0 }, 'Stroke has to be above zero, or leave it blank.'],
      'a side that is not finite' => [{ width: '1e999' }, 'Width needs a number above zero.'],
      'too many notches' => [{ width: 1000, thickness: 0.01 }, '150 is the most we draw']
    }.each do |what, (change, message)|
      it "answers 422 for #{what}" do
        get '/box/download.pdf', params: { box: box.merge(change) }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(message)
      end
    end

    it 'answers 422 for a box that is not a set of fields' do
      get '/box/download.pdf', params: { box: 'abc' }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'answers 422 when laser-cutter gives up' do
      allow_any_instance_of(BoxRequest).to receive(:render).and_raise(Laser::Cutter::Error, 'no such notch') # rubocop:disable RSpec/AnyInstance

      get '/box/download.pdf', params: { box: box }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to eq 'laser-cutter could not draw this box: no such notch'
    end
  end
end
