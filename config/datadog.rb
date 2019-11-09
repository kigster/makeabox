require 'ddtrace'
require 'redis'

Datadog::Tracer.log = Logger.new(nil)
# This is the port we have configured in the /etc/datadog/datadog.yml (apm_config)
Datadog.tracer.configure(port: 9126, enabled: true)

program = 'makeabox'.freeze

if %w(staging production).include?(ENV['RAILS_ENV'])
  require 'dalli'

  # Here we register Rails services and override automatically generated names by Datadog
  # with something more sensible in our context. We rename the tracers based on what process
  # they are (i.e. -rails-tasks, or -rails-puma) and whether it's not rails at all, but redis
  # or dalli.
  Datadog.configure do |c|

    c.analytics_enabled = true

    c.tracer enabled: true

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#rails
    c.use :rails,
      service_name: program,
      controller_service: program + '-controller',
      cache_service: program + '-cache',
      distributed_tracing: true,
      middleware_names: true

    c.use :http, service_name: program + '-http-outbound'

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#sidekiq
    c.use :sidekiq, service_name: program

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#redis
    c.use :redis, service_name: program + '-redis'

    # https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#dalli
    c.use :dalli, service_name: program + '-memcached'

  end
else
  Datadog.configure do |c|
    c.tracer enabled: false
  end
end
