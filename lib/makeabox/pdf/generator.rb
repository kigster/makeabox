# frozen_string_literal: true

module Makeabox
  module PDF
    class Generator
      include WithLogging
      include RedisConcern

      attr_reader :config, :session_id, :job_id
      attr_accessor :pdf_file, :generation_status

      def initialize(config:, session_id:, job_id:)
        @config = Laser::Cutter::Configuration.new
        @config.merge!(config)
        @config.delete(:session_id)

        @session_id        = session_id
        @job_id            = job_id
        @generation_status = GenerationStatus.new
        start_job
      end

      def start_job
        with_redis do |redis|
          redis.zadd(session_id, Time.now.to_i, job_id)
        end
      end

      def complete_job(pdf_file_name)
        with_redis do |redis|
          redis.pipelined do
            # grab the start time of the job
            start_time = redis.zmscore(session_id, job_id)
            if start_time.nil?
              raise ArgumentError, "Job #{job_id} is not associated with session #{session_id}"
            end

            start_time = start_time.first if start_time.is_a?(Array)

            # remove the job from the sorted set
            redis.zrem(session_id, job_id)

            generation_status.job_finished(pdf_file:   pdf_file_name,
                                           start_time: start_time,
                                           redis:      redis,
                                           job_id:     job_id)
          end
        end

        generation_status
      end

      def generate!
        logging('generating PDF', config: config) do
          Laser::Cutter::Renderer::LayoutRenderer.new(config).render
        end

        complete_job(config.file)
      rescue StandardError => e
        @latest_error = e.message
        Rails.logger.error("ERROR: #{e.inspect}\n#{e.backtrace.join("\n")}")
        raise(e)
      end
    end
  end
end
