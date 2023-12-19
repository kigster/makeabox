# frozen_string_literal: true

require 'makeabox'

class GeneratePDFWorker < AbstractWorker
  # @see https://github.com/mhenrixon/sidekiq-unique-jobs
  sidekiq_options lock: :until_and_while_executing, lock_timeout: Makeabox::PDF_GENERATION_TIMEOUT, retry: 0,
                  on_conflict: { client: :log, server: :reject }

  def perform(config)
    logging('generating PDF', config: config) do |extra|
      generator = Makeabox::PDF::Generator.new(config: config, session_id: config["session_id"], job_id: jid)
      generator.generate!.tap do |status|
        extra[:message] = status.to_h
      end
    end
  end
end
