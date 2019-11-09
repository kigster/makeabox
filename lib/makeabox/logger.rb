require 'tty-logger'
module Makeabox
  # This is the module you include to get :info, :error, etc methods.
  module Logging
    class << self
      def included(base)
        base.extend(LoggingMethods)
        base.include(LoggingMethods)
      end
    end
  end

  module LoggingMethods
    BlockResult     = Struct.new(:log_method, :message, :value)
    LOGGING_METHODS = %i(
      debug
      info
      success
      wait
      warn
      error
      fatal
    )

    extend Forwardable
    def_delegators :logger, *LOGGING_METHODS

    def logger
      LoggingWrapper.logger
    end

    # This method is supposed to wrap a block of code, so that it can log the duration
    # and the message, for example:
    #
    # @Example of wrapping user authentication
    #
    #    class UsersController
    #       def login
    #          with_logging("user #{params['user']} attempted to login") do
    #            User.find(params['user']).&authenticate!(params['password'])
    #          end
    #       end
    #    end

    def with_logging(message,
                     swallow_exceptions: [],
                     start: Time.now,
                     elapsed_time: 0,
                     result: BlockResult.new(:info))
      result.value = yield
      elapsed_time = Time.now - start
      logger.send("(#{"%9.2f" % (1000 * elapsed_time)}ms) #{message} #{result.message}")
      result.value
    rescue *swallow_exceptions => e
      elapsed_time = Time.now - start
      logger.warn "(#{"%9.2f" % (1000 * elapsed_time)}ms) warning: #{e.message} for #{message} #{result.message}"
    rescue StandardError => e
      logger.error "(#{"%9.2f" % (1000 * elapsed_time)}ms) error: #{e.message} for #{message}"
    end
  end

  module LoggingWrapper
    def self.logger
      @logger ||= TTY::Logger.new(fields: { app: 'makeabox', 'env': Rails.env.to_s}) do |config|
        config.metadata = [:pid, :date, :time],
        config.types    = {
            thanks: { level: :info },
            done:   { level: :info }
        }
        config.handlers = [
            [:console, {
                styles: {
                    thanks: {
                        symbol:   "❤️ ",
                        label:    "thanks",
                        color:    :magenta,
                        levelpad: 0
                    },
                    done:   {
                        symbol:   "!!",
                        label:    "done",
                        color:    :green,
                        levelpad: 2
                    }
                }
            }]
        ]
      end
    end
  end

end

