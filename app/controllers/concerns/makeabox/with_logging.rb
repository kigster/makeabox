# frozen_string_literal: true
module Makeabox
  module WithLogging
    def logging(*args, **opts)
      extra  = { message: args.join('. ') }
      t1     = Time.now
      result = yield(extra)
      t2     = Time.now - t1
      Rails.logger.info(JSON.dump(
                          level: 'info',
                          message: extra[:message],
                          duration: format('%.2fms', (t2 * 1000)),
                          **opts
                        ))
      result
    end
  end
end
