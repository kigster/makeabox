# frozen_string_literal: true

require 'colored2'
require 'logger'
require 'yaml'
require 'digest'

module MakeABox
  module Logging
    # This module is meant to be included in the +{ApplicationController}+
    module ControllerHelpers
      class << self
        # This constant lists all methods from the including context that must be
        # available to #log_incoming_request method.
        DEPENDS_ON_CONTEXT_METHODS = %i[action_name params request response session].freeze

        def validate_context!(base)
          DEPENDS_ON_CONTEXT_METHODS.all? do |method|
            unless base.respond_to?(method)
              raise ArgumentError,
                    "#log_incoming_request needs method [#{method}] in the context of #{base.name}"
            end
          end
        end

        def included?(base)
          validate_context!(base)
          base.include(LoggerInstanceMethods)
        end
      end

      # These are error classes that, if thrown inside the log_incoming_request method,
      # are not logged as errors.
      SILENT_ERRORS_WEB = %w[
        ActionController::RoutingError
        ActionController::UnknownFormat
      ].freeze

      # @description This method should be called from a Rails "around" action
      # filter. It uses the {request} and {response} objects to log
      # one line per request, which includes the source information about
      # the user and the latency of the request. The format has been meticulously
      # adjusted to be both compact and very readable, as well as parseable by
      # libraries such as Turnstile (that count concurrent users).
      #
      # @example
      #
      #      class ApplicationController
      #         include MakeABox::Logging::ControllerHelpers
      #         around_action :log_incoming_request
      #      end
      #
      def log_incoming_request(&_block)
        level, message = construct_log_message
        log_block(message,
                  level: level,
                  silent_errors: silent_errors,
                  rescue_errors: []) do
          yield if block_given?
        end
      end

      private

      def silent_errors
        @silent_errors ||= ::MakeABox::Logging.constantize_array(SILENT_ERRORS_WEB)
      end

      def construct_log_message
        level = :info
        xhr = request.xhr? ? HTTP_XHR : HTTP_REQ
        method = request.method.to_s.upcase
        log_params = request.filtered_parameters
        log_params = log_params.respond_to?(:except) ? log_params.except('controller', 'action', 'format') : log_params

        http_map = ::MakeABox::Logging.http_response_mapping
        if response&.status
          code = response.status
          level = http_map[http_map.keys.find { |range| range.include?(code) }]
        end

        message = [
          'x-rqst',
          format('%-15s', request.ip),
          format('%32.32s', request.session.id),
          "#{xhr} #{format '%-6s', method.to_s}",
          (response ? response.code.to_s : NIL_RESPONSE),
          request_path_and_action + (log_params.empty? ? '' : " ◀— params:\n#{log_params.awesome_inspect}")
        ].compact.join(' │ ')
        [level, message]
      end

      def sprintf_elapsed_time(elapsed_time)
        format '%7.3fs', (elapsed_time.to_f / 1000.0)
      end

      def request_path_and_action
        "#{format('%s', request.path_info).magenta.bold} (#{self.class.name.bold.blue}##{action_name.green})"
      end

      # This is currently unused, because we aren't able to reliably detect current
      # user.
      def user_hash
        LOGGED_OUT
      end

      LOGGED_OUT = 'logged-out'
      HTTP_XHR = 'XHR'
      HTTP_REQ = 'REQ'
      NIL_RESPONSE = '---'
    end
  end
end
