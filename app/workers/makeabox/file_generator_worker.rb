require 'laser-cutter/renderer/layout_renderer'
require 'hashie/mash'


class FileGeneratorWorker
  include Makeabox::AbstractWorker

  def perform(config = {}, session_id = nil)
    STDERR.puts "config: #{config.inspect}, session_id: #{session_id}"
    Rails.logger.warn("PDF GENERATOR: session_id: #{session_id}, config is #{config}")
    Laser::Cutter::Renderer::LayoutRenderer.new(Hashie::Mash.new(config)).render
  end
end

