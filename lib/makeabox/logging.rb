# frozen_string_literal: true
# see: https://www.mikeperham.com/2018/02/28/ruby-optimization-with-one-magic-comment/
#
# We use #freeze here exceedingly because log methods are typically called often and a lot.
# Without freezing strings we'd be creating a short-lived object *on every call*.

require 'colored2'
require 'logger'
require 'yaml'
require 'digest'

Colored2.disable! if ENV['DISABLE_LOG_COLORS']

module MakeABox
  # This module is meant to be included in a class or a controller to enable effective
  # and colorful logging to the development/staging/production.log
  #
  # Unlike standard Rails Logger, this logger logs timestamps up to milliseconds, making
  # it easy to find bottlenecks in code.
  #
  # @example You can use it directly, ie. MakeABox::Logging.logger
  #              or you can include this module
  #
  #      class Foo
  #         include ::MakeABox::Logging
  #         def initialize
  #            info('created new Foo', 'at', Time.now)
  #         end
  #      end
  #
  module Logging
    MUTEX ||= Mutex.new.freeze

    # Right hand side is a list of methods to call on the corresponding
    # string, in the specified order:
    SEVERITY_COLORS ||= {
      debug: %i(green),
      info: %i(blue),
      warn: %i(yellow),
      error: %i(red),
      fatal: %i(red bold italic)
    }.freeze

    # When the logger is first created, this is the default map based on the
    # Rails environment.
    DEFAULT_SEVERITY_MAPPING ||= {
      'development' => :debug,
      'staging' => :debug,
      'production' => :info,
      'test' => :debug
    }.freeze

    # This matrix represents the log level used for each type
    # of HTTP response.
    HTTP_RESPONSE_MAPPING ||= {
      (0..399) => :info,
      (400..499) => :warn,
      (500..999) => :error
    }.freeze

    ARROW_SYMBOL ||= ' ⤶ '
    MULTILINE_START_SYMBOL ||= '   ⤷  '
    MULTILINE_CONTINUE_SYMBOL ||= '    │ '

    LOG_LEVELS ||= %i(debug info warn error fatal).freeze

    class << self
      def included(base)
        base.include(LoggerInstanceMethods)
      end

      def severity_colors
        ::MakeABox::Logging::SEVERITY_COLORS
      end

      def default_severity
        ::MakeABox::Logging::DEFAULT_SEVERITY_MAPPING
      end

      def http_response_mapping
        ::MakeABox::Logging::HTTP_RESPONSE_MAPPING
      end

      def detect_rails_env
        defined?(Rails) ? Rails.env : (ENV['RAILS_ENV'] || 'development')
      end

      def constantize_array(array)
        array.map do |klass|
          Kernel.const_get(klass) if Kernel.const_defined?(klass)
        end.compact
      end
    end
  end
end

# logging_glob = File.expand_path('./logging', __dir__)
Dir.glob("#{__dir__}/logging/*.rb").each do |file|
  require(file)
end
