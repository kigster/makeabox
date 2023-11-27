# frozen_string_literal: true

require 'redis'
require 'hiredis-client'
require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'makeabox'

Sidekiq.configure_server do |config|
  config.redis = { url: "#{Makeabox::REDIS_URL}/10", driver: :hiredis }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: "#{Makeabox::REDIS_URL}/10", driver: :hiredis }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.strict_args!(false)
