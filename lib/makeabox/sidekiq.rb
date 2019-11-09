require 'sidekiq'
require 'dalli'
require 'hiredis' unless RUBY_PLATFORM == "java"
require 'redis'

require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'connection_pool'

module Makeabox
  module ConfigureSidekiq
    class << self
      def initialize!
        ::Sidekiq.default_worker_options = { :backtrace => true }

        Sidekiq.configure_server do |config|
          config.redis = redis_pool_proc[]
        end

        Sidekiq.configure_client do |config|
          config.redis = redis_pool_proc[]
        end

        Sidekiq::Extensions.enable_delay!
      end

      def config
        ::Settings.config.sidekiq
      end

      private

      def redis_connection_proc
        proc { ::Redis.new(**config.sidekiq.redis.to_h) }
      end

      def redis_pool_proc
        proc { ::ConnectionPool.new(size: config.pool_size,
                                    &redis_connection_proc) }
      end
    end
  end
end

Makeabox::ConfigureSidekiq.initialize!
