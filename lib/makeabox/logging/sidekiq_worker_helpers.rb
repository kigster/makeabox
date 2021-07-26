# frozen_string_literal: true

require 'colored2'
require 'logger'
require 'yaml'
require 'digest'

module Makeabox
  module Logging
    # This module should be prepended to the inheritance chain of any +SidekiqWorker+, for example
    #
    # @example of a worker:#
    #
    #      class TestWorker
    #         include Sidekiq::Worker
    #         def perform(*args)
    #           # ...
    #         end
    #      end
    #
    #      TestWorker.prepend(::Makeabox::Logging::SidekiqWorkerHelpers)
    #
    module SidekiqWorkerHelpers
      SILENT_ERRORS_SIDEKIQ = %w[
        Adp::UpdateCredentialsWorker::AdpCredsFetcherError
      ].freeze

      def perform(*args, &block)
        opts = self.class.respond_to?(:sidekiq_options) ? self.class.sidekiq_options : {}
        extra_opts = opts.except('queue', 'retry')
        msg = [
          'x-job ',
          queue_name(opts) + retry_info(opts),
          "#{self.class.name.blue}(#{args.to_s[1..-2]}) " +
            (extra_opts.empty? ? '' : extra_opts.inspect)
        ].join(' │ ')

        log_block(msg,
                  level: :info,
                  silent_errors: silent_errors) do
          super(*args, &block)
        end
      end

      private

      def silent_errors
        @silent_errors ||= ::Makeabox::Logging.constantize_array(SILENT_ERRORS_SIDEKIQ)
      end

      def retry_info(opts)
        format('r: %-5.5s', (opts['retry'] || ' '))
      end

      QUEUE_COLORS = {
        'default' => :green,
        'critical' => :yellow,
        'messaging' => :blue,
        'system_messages' => :magenta,
        default: :green,
        critical: :yellow,
        messaging: :blue,
        system_messages: :magenta
      }.freeze

      def queue_name(opts)
        q = opts['queue'] || 'default'
        color = QUEUE_COLORS[q] || :red
        format('q: %-10.10s', q).send(color)
      end
    end
  end
end
