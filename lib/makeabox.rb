# frozen_string_literal: true

# @description Primary module for the application
module Makeabox
  class << self
    def live?
      Rails.env.production? && Etc.uname[:sysname] =~ /linux/i
    end
  end

  VERSION = '3.0.2'

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

  def self.memcached_options(namespace = nil)
    opts      ||= {}
    namespace ||= ''
    namespace = namespace.to_s
    namespace += ".#{Rails.env.to_s[0]}"
    MEMCACHED_CONFIG.dup.merge(opts.merge({ namespace: namespace }))
  end
end
