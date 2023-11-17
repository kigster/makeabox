# frozen_string_literal: true

module Makeabox
  # This module adds a #logging method that can be used to log a block of execution
  module WithLogging
    protected

    # Method should be called with a block, which receives a hash called `extra`,
    # where `extra[:message]` is the message that will be printed upon block completion.
    # Therefore the block is able to alter the log message post execution.
    # @param *args Array arguments are joined with a command stringified
    # @param **opts Hash arguments are passed into the JSON logger as is
    def logging(*args, **opts)
      extra  = { message: args.join('. ') }
      t1     = Time.now
      result = yield(extra)
      t2     = Time.now - t1
      Rails.logger.info(
        JSON.dump(
          level: 'INFO',
          message: extra[:message],
          duration: format('%.2fms', (t2 * 1000)),
          **opts
        )
      )
      result
    end
  end
end
