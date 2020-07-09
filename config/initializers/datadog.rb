# frozen_string_literal: true

# config/initializers/datadog.rb

require 'etc'

tracing_enabled = (
ENV['DATADOG_ENABLED'] &&
  Etc.uname[:sysname] =~ /linux/ &&
  ENV['RAILS_ENV'] == 'production'
)

require 'ddtrace'
if tracing_enabled
  program = 'makeabox'

  # Here we register Rails services and override automatically generated names by Datadog
  # with something more sensible in our context. We rename the tracers based on what process
  # they are (i.e. -rails-tasks, or -rails-puma) and whether it's not rails at all, but redis
  # or dalli.
  Datadog.configure do |c|
    c.logger = Rails.logger

    if tracing_enabled
      c.tracer enabled: true, port: 9126
    end

    c.analytics_enabled = true

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#rails
    c.use :rails,
          service_name:        program,
          controller_service:  program + '-controller',
          distributed_tracing: true,
          middleware_names:    true

    c.use :http, service_name: program + '-http-outbound'

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#sidekiq
    # c.use :sidekiq, service_name: program

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#redis
    # c.use :redis, service_name: program + '-redis'

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#dalli
    # c.use :dalli, service_name: program + '-memcached'

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#aws
    # c.use :aws, service_name: program + '-aws'
  end
else
  Datadog.configure do |c|
    c.tracer enabled: false
  end
end
