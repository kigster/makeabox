# frozen_string_literal: true

# config/initializers/datadog.rb

require 'etc'

module Makeabox
  DATADOG_ENABLED =
    (
      ENV['DATADOG_ENABLED'] == '1' &&
      Etc.uname[:sysname] =~ /linux/i &&
      ENV['RAILS_ENV'] == 'production'
    )
end

if Makeabox::DATADOG_ENABLED
  require 'ddtrace'
  require 'datadog/statsd'

  ENV['DATADOG_ENABLED'] = '1'
  program                = 'makeabox'

  # Here we register Rails services and override automatically generated names by Datadog
  # with something more sensible in our context. We rename the tracers based on what process
  # they are (i.e. -rails-tasks, or -rails-puma) and whether it's not rails at all, but redis
  # or dalli.
  f = File.new('log/datadog.log', 'w+') # Log messages should go there

  Datadog.configure do |c|
    c.enabled      = true
    c.logger       = Logger.new(f)
    c.logger.level = ::Logger::INFO
    c.tracer enabled: true
    c.tracer.port                  = 9126
    c.tracer.partial_flush.enabled = true

    c.runtime_metrics.enabled = true
    c.runtime_metrics.statsd  = Datadog::Statsd.new

    c.sampling.default_rate = 1.0
    # To enable debug mode:
    c.diagnostics.debug = true
    c.analytics_enabled = true
    c.tags              = {
      app: program,
      language: 'ruby',
      env: Rails.env.to_s,
      branch: 'master',
      revision: `git rev-parse HEAD`,
      kernel: Etc.uname[:sysname],
      program_name: File.basename($PROGRAM_NAME)
    }

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#rails
    c.use :rails,
          service_name: program,
          controller_service: "#{program}-controller",
          distributed_tracing: true,
          middleware_names: true,
          log_injection: true

    c.use :http, service_name: "#{program}-http"

    c.use :action_view, service_name: "#{program}-action-view"

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#sidekiq
    # c.use :sidekiq, service_name: program

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#redis
    c.use :redis, service_name: "#{program}-redis"

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#dalli
    c.use :dalli, service_name: "#{program}-memcached"

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#aws
    # c.use :aws, service_name: program + '-aws'
  end
end
