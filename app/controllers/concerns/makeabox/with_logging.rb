# frozen_string_literal: true

module Makeabox
  # This module adds a #logging method that can be used to log a block of execution
  module WithLogging
    protected

    # Runs the block and logs how long it took, whether or not it raised. The block receives a hash
    # `extra`, and may change `extra[:message]` to alter what is logged.
    #
    # @param args [Array<String>] joined with '. ' to make the message
    # @return whatever the block returns
    def logging(*args)
      extra = { message: args.join('. ') }
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield(extra)
    rescue Exception => e # rubocop:disable Lint/RescueException
      extra[:message] += " | failed: #{e.class}"
      raise
    ensure
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      Rails.logger.info("duration ➜ #{format('%.2f', duration)}s | #{extra[:message]}")
    end
  end
end
