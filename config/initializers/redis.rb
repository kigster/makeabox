# frozen_string_literal: true

# Redis connection pool for the box counters.
#
# Redis runs on the same host and listens on 127.0.0.1 only. Puma serves
# requests from several threads, so each thread borrows a connection from a
# pool instead of sharing one client.
#
# Timeouts are short on purpose. A slow or stopped Redis must never hold up
# a box download, so callers rescue Redis::BaseError and move on.
#
# Each environment gets its own database index so development and test runs
# never touch production counts. Set REDIS_URL to override.
#
#   REDIS.with { |r| r.incr('downloads') }

require 'connection_pool'
require 'redis'

redis_db = { 'production' => 0, 'development' => 1, 'test' => 2 }.fetch(Rails.env, 1)
redis_url = ENV.fetch('REDIS_URL', "redis://127.0.0.1:6379/#{redis_db}")

REDIS = ConnectionPool.new(
  size:    Integer(ENV.fetch('RAILS_MAX_THREADS', 5)),
  timeout: 0.5
) do
  Redis.new(
    url:                redis_url,
    connect_timeout:    0.2,
    read_timeout:       0.2,
    write_timeout:      0.2,
    reconnect_attempts: 1
  )
end
