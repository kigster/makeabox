# frozen_string_literal: true

module MakeABox
  module Logging
    # Module +{MakeABox::Logging::BlockHelpers}+ offers a primary method +log_block+,
    # which takes a message, logging level, a list of exceptions to rescue or to
    # silently ignore, and a block to execute. It then runs the block, measures the time
    # it takes for it to finish, and logs one line per block execution, dealing with
    # any errors or exceptions in consistent and predictable basis.
    module BlockHelpers
      SUCCESS = ' ✔ '.bold.green.freeze
      FAILED = 'ERR'.bold.red.freeze
      RESCUED = 'RES'.bold.yellow.freeze
      SEP = ' │ '

      # This method is a block helper that can be used to measure
      # execution time of a block and log it to the appropriate application
      # log file using Rails.logger
      #
      # In addition, if the block throws an error, the method automatically
      # logs and re-raises it. If re-raising is not desire, and we'd rather
      # swallow the error, then pass simply `rescue: true`
      #
      # @example
      #   log_block('computed integral of flux capacitors',
      #     level: :info,
      #     silent_errors: [ ::ActiveRecord::RecordNotFound ],
      #     rescue_errors: [ ::ActiveRecord::RecordNotFound ]) do
      #
      #     # computing flux capacitors
      #     sleep 1
      #   end
      #
      # @param [String] message to log
      # @param [Symbol] level to log at
      # @param [Array<Exception>] silent_errors an array of error classes to not log as errors
      # @param [Array<Exception>] rescue_errors an array of error classes to rescue if thrown
      def log_block(message, level: :info, silent_errors: [], rescue_errors: [], &_block)
        start = Time.now
        error_message = nil
        yield.tap { message = SUCCESS + SEP + message } if block_given?
      rescue StandardError => e
        # Now deal with errors that should be rescued, or silently ignored:
        if rescue_errors.find { |error_class| e.is_a?(error_class) }
          level = :warn
          error_message = "rescued: #{e.inspect.red}"
          message = RESCUED + SEP + message.red
        elsif silent_errors.find { |error_class| e.is_a?(error_class) }
          # If it's a "silent" error, do not log it at error level, but still re-raise. To
          # swallow this error, add it to both  +{silent_errors}+ and +{rescue_errors}+.
          level = :warn
          error_message = nil
          message = FAILED + SEP + message.red
          raise e
        else
          error_message = "raised: #{e.inspect.red}"
          level = :error
          message = FAILED + SEP + message.red
          raise e
        end
        nil
      ensure
        elapsed_time = Time.now - start
        final_message = "time: #{format('%8.1f', (1000 * elapsed_time))}ms".cyan.italic + " #{message}"
        MakeABox::Logging.logger.send(level, final_message)
        MakeABox::Logging.logger.error(error_message) if error_message
        begin
          if block_error && !silent_errors.find { |error_class| block_error.is_a?(error_class) }
            report_error_to_stderr(message, block_error)
          end
        rescue StandardError
          nil
        end
      end

      def report_error_to_stderr(message, e)
        return if ENV['CI']

        warn "\n\n"
        warn " EXCEPTION : #{e.message.bold.red} (#{e.to_s.red})\n"
        warn "   CONTEXT : #{self.class.name.bold.yellow}\n"
        warn "   PAYLOAD : #{message.bold.yellow}\n"
        if e.backtrace.is_a?(Array)
          top_stack = e.backtrace[0..20]
          if top_stack.present?
            first_stack = top_stack.shift
            warn " STACKTRACE (reversed)\n"
            warn "    #{top_stack.reverse.join("\n    ").red.italic}"
            warn "    #{first_stack.bold.red.italic.underlined}"
            $stderr.puts
          end
        else
          $stderr.printf '  (no backtrace available): '.bold.yellow.freeze
        end
        $stderr.puts
      end
    end

    # This may seem unnecessary, but being able to measure duration of various
    # pieces of logic and log it from anywhere in the codebase is rather powerful.
    #
    # @example Using  +log_block+
    #    log_block "counting all users", rescue: true do
    #       puts User.all.count
    #    end
    Object.include(BlockHelpers)
  end
end
