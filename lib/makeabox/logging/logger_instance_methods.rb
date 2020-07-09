# frozen_string_literal: true

require 'colored2'
require 'logger'
require 'yaml'
require 'digest'

module MakeABox
  module Logging
    module LoggerInstanceMethods
      def logger
        return @logger if @logger

        ::MakeABox::Logging::MUTEX.synchronize do
          @logger = create_logger
        end
      end

      def logger=(value = nil)
        return @logger if @logger == value

        ::MakeABox::Logging::MUTEX.synchronize do
          @logger = value
        end
      end

      # Generates instance methods named as the list below, eg:
      #  +self.info+, +self.debug+ etc.
      LOG_LEVELS.each do |level|
        send(:define_method, level) do |*args, &block|
          logger_log(level, *args, &block)
        end
      end

      # This function always returns a new ::Logger instance.
      LOG_LEVEL_OVERRIDE_ENV ||= 'MAKEABOX_LOG_LEVEL'

      def create_logger
        rails_env = ::MakeABox::Logging.detect_rails_env
        logger = ::Logger.new("log/#{rails_env}.log")

        logger.formatter = logger_format_proc

        level = ENV[LOG_LEVEL_OVERRIDE_ENV].to_sym if ENV[LOG_LEVEL_OVERRIDE_ENV]
        level ||= ::MakeABox::Logging.default_severity[rails_env]

        logger.level = log_level_from_sym(level)
        logger.progname = 'rails'
        logger
      end

      private

      # This method returns a proc that is capable of formatting the incoming
      # log message. Freezing strings here is paramount.
      LOG_FORMAT_SEPARATOR ||= ' ❯❯❯ '.bold.yellow.freeze

      def logger_format_proc
        @logger_format_proc ||= proc do |severity, datetime, _program_name, message|
          # This is only necessary because in some places we call  +Rails.logger+
          # In that case, we must ensure that we are not logging filtered messages.
          color = ::MakeABox::Logging.severity_colors[severity.downcase.to_sym] || :normal
          sev = sprintf '%-6.6s', severity
          date = sprintf '%23.23s ', datetime.strftime('%Y-%m-%d %H:%M:%S.%L')
          thread = sprintf '%-14s', thread_name
          combined_message(severity, sev, thread, color, date, message)
        end
      end

      def combined_message(severity, sev, thread, color, date, message)
        [
          colorize(sev.to_s[0].upcase, color),
          date.yellow.bold,
          format_pid_ppid,
          thread.bold.green.italic + LOG_FORMAT_SEPARATOR +
            (severity == 'INFO' ? message : colorize(message, color)) +
            "\n"
        ].join('│')
      end

      def format_pid_ppid
        sprintf(' %5d', Process.pid).magenta.bold +
          ::MakeABox::Logging::ARROW_SYMBOL + sprintf('%5d ', Process.ppid).blue.bold
      end

      def log_level_from_sym(level)
        log_level = level.to_s.upcase.to_sym
        if ::Logger.const_defined?(log_level)
          ::Logger.const_get(log_level)
        else
          ::Logger::INFO
end
      end

      # we use inject to sequentially apply all color modifications
      # to the initial argument.
      def colorize(arg, colors)
        Array(colors).inject(arg) { |memo, color| memo.send(color) }
      end

      def thread_name
        Thread.current[:name] ||= Thread.current.object_id
        sprintf ' th-%-9.9s', Thread.current[:name]
      end

      def logger_log(level, *args, &block)
        logger.send(level, *args, &block) if defined?(Logger)
      end
    end

    extend LoggerInstanceMethods
  end
end
