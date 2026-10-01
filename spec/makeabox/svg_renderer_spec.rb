# frozen_string_literal: true

require 'rails_helper'
require 'tempfile'

RSpec.describe Makeabox::SvgRenderer do
  def render(renderer_class)
    Tempfile.create(['box', '.svg']) do |file|
      config = Laser::Cutter::Configuration.new(width: 5, height: 3, depth: 4, thickness: 0.245, units: 'in', file: file.path)
      renderer_class.new(config).render
      File.read(file.path)
    end
  end

  it 'writes exactly what laser-cutter writes' do
    expect(render(described_class)).to eq render(Laser::Cutter::Renderer::SvgRenderer)
  end

  it 'works out the size of the page once, not once per line' do
    config = Laser::Cutter::Configuration.new(width: 5, height: 3, depth: 4, thickness: 0.245, units: 'in', file: File::NULL)
    renderer = described_class.new(config)
    expect(renderer.subject).to receive(:enclosure).at_least(:once).at_most(4).times.and_call_original

    renderer.render
  end
end
