# frozen_string_literal: true

require 'connection_pool'

# @description Primary module for the application
module Makeabox
  VERSION = '3.1.0'

  REDIS_URL = 'redis://127.0.0.1:6379'

  PDF_GENERATION_TIMEOUT = 5.minutes

  class << self
    attr_accessor :progress_redis

    def live?
      Rails.env.production? && Etc.uname[:sysname] =~ /linux/i
    end
  end

  VERSION = '3.0.3'
  MEMCACHED_CONFIG = {
    socket_timeout: 0.2,
    expires_in:     10.minutes,
    keepalive:      true,
    compress:       true,
    pool:           {
      sizes:   10,
      timeout: 30
    },
  }.freeze

  MEMCACHED_PORT = ENV.fetch('MEMCACHED_PORT', 11_211)
  MEMCACHED_HOST = ENV.fetch('MEMCACHED_HOST', 'localhost')
  MEMCACHED_URL  = "#{MEMCACHED_HOST}:#{MEMCACHED_PORT}".freeze

  self.progress_redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: "#{REDIS_URL}/1") }

  def self.memcached_options(namespace = nil)
    opts      ||= {}
    namespace ||= ''
    namespace = namespace.to_s
    namespace += ".#{Rails.env.to_s[0]}"
    MEMCACHED_CONFIG.dup.merge(opts.merge({ namespace: namespace }))
  end
end
