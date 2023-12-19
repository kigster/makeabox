# frozen_string_literal: true

module Makeabox
  module PDF
    class GenerationStatus
      include WithLogging
      include RedisConcern

      attr_accessor :size, :file, :result, :error, :duration, :job_id

      def initialize(file: nil, result: nil, error: nil, duration: nil)
        @file     = file
        @result   = result
        @error    = error
        @duration = duration
        @size     = File.size(file) if file && File.exist?(file)

        info "Received PDF generation result: #{to_h}"
      end

      def job_finished(pdf_file:, start_time:, redis:, job_id:)
        self.job_id = job_id
        # now we create a hash for the job status
        self.duration = Time.now.to_i - start_time

        if File.exist?(pdf_file)
          self.file   = pdf_file
          self.result = 'done'
          self.size   = File.size(pdf_file)
        else
          self.result = 'error'
          self.error  = error
        end

        raise ArgumentError, "Job appears to not be valid, and does not contain all elements: #{to_h}" unless valid?

        save_status(redis)
      end

      def valid?
        job_id.present? && result.present?
      end

      def save_status(redis)
        redis.hset(job_key, 'file', file) if file
        redis.hset(job_key, 'size', size) if size
        redis.hset(job_key, 'result', result) if result
        redis.hset(job_key, 'error', error) if error
        redis.hset(job_key, 'duration', duration) if duration

        redis.expire(job_key, 5.minutes.to_i)
      end

      def done?
        result == 'complete'
      end

      def error?
        result == 'error'
      end

      def to_h
        {
          file:     file,
          size:     size,
          result:   result,
          error:    error,
          duration: formatted_duration(duration)
        }
      end

      private

      def formatted_duration(total_seconds)
        return nil if total_seconds.nil?

        total_seconds = total_seconds.round # to avoid fractional seconds potentially compounding and messing up seconds, minutes and hours
        hours         = total_seconds / (60 * 60)
        minutes       = (total_seconds / 60) % 60 # the modulo operator (%) gives the remainder when leftside is divided by rightside. Ex: 121 % 60 = 1
        seconds       = total_seconds % 60
        [hours, minutes, seconds].map do |t|
          # Right justify and pad with 0 until length is 2.
          # So if the duration of any of the time components is 0, then it will display as 00
          t.round.to_s.rjust(2, '0')
        end.join(':')
      end
    end
  end
end
