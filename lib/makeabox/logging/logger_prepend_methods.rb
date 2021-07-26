# frozen_string_literal: true

require 'colored2'
require 'logger'
require 'yaml'
require 'digest'

module Makeabox
  module Logging
    module LoggerPrependMethods
      LOG_LEVELS.each do |level|
        send(:define_method, level) do |*args, &_block|
          lines = args.join.split(/\n/)
          count = 0
          lines.each do |message|
            next if message.empty? || message =~ /^\s*$/
            next if filter_log_arguments?(message)

            message = MULTILINE_START_SYMBOL + message if count == 1
            message = MULTILINE_CONTINUE_SYMBOL + message if count > 1
            super(message)
            count += 1
          end
        end
      end

      private

      def filter_log_arguments?(args)
        Array(args).any? do |arg|
          ::Makeabox::Logging::LoggingFilters.active_filters.any? { |r| arg =~ r }
        end
      end
    end

    ::Logger.prepend(LoggerPrependMethods)
  end
end
