# frozen_string_literal: true

require 'forwardable'
require 'singleton'

module Makeabox
  class Cache
    include Singleton

    def memcached
      @memcached ||= ConnectionPool.new(size:    config.pool_size,
                                        timeout: config.timeout) do
        Dalli::Client.new(*config.hosts, **config.cache.to_h)
      end
    end

    def client
      memcached.with do |client|
        return client
      end
    end

    private

    def config
      ::Settings.config.memcached
    end

    class << self
      extend Forwardable
      def_delegators :cache, :fetch, :delete, :flush

      def cache_fetch(key, ttl = nil, options = nil, &block)
        with_cache { |client| client.fetch(key, ttl, options, &block) }
      end

      def cache_delete(key)
        with_cache { |client| client.delete(key) }
      end

      def cache_write(key)
        with_cache { |client| client.write(key) }
      end

      def with_cache
        instance.memcached.with do |client|
          yield(client) if block_given?
        end
      end

      def cache
        instance
      end

      alias initialize! cache
    end
  end
end

Makeabox::Cache.initialize!
