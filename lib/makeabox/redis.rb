# frozen_string_literal: true

require 'hiredis' unless RUBY_PLATFORM == "java"
require 'redis'
require 'connection_pool'

module Makeabox
  module ConfigureRedis
    class << self
      def initialize!
        redis
      end

      def redis
        @redis ||= ::ConnectionPool::Wrapper.new(size: 5, timeout: 3) do
          ::Redis.new(redis_connection_options)
        end
      end

      def redis_connection_options
        ::Settings.config.redis.sidekiq.to_h
      end
    end
  end

  class << self
    def with_redis
      ConfigureRedis.redis.with do |redis_client|
        yield(redis_client)
      end
    end
  end
end

Makeabox::ConfigureRedis.initialize!
