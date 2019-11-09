require 'sidekiq'
require 'dalli'
require 'hiredis'
require 'redis'

require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'connection_pool'

Sidekiq.default_worker_options = { :backtrace => true }

sidekiq_redis_opts = {
    url:             Settings.config.sidekiq.redis.url,
    namespace:       Settings.config.sidekiq.redis.namespace,
    network_timeout: Settings.config.sidekiq.redis.network_timeout,
    driver:          :hiredis
}

single_redis_connection     = proc { ::Redis.new(sidekiq_redis_opts) }
redis_connection_pool_proc  = proc { ::ConnectionPool.new(size: Settings.config.sidekiq.redis.pool_size,
                                                          &single_redis_connection) }

Sidekiq.configure_server do |config|
  config.redis = redis_connection_pool_proc[]
end

Sidekiq.configure_client do |config|
  config.redis = redis_connection_pool_proc[]
end

Sidekiq::Extensions.enable_delay!
