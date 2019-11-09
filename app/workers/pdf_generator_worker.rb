require 'laser-cutter/renderer/layout_renderer'

module Workers
  class PDFGeneratorWorker

    include Sidekiq::Worker
    sidekiq_options queue: 'fast'

    def perform(config, session_id)
      Rails.logger.warn("PDF GENERATOR: session_id: #{session_id}, config is #{config}")

      Laser::Cutter::Renderer::LayoutRenderer.new(config).render
    end
  end
end

