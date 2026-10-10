# frozen_string_literal: true

# Serves makeabox on the old server (behind nginx, see config/deploy) and in a
# container (Cloud Run, see Dockerfile). The container sets PORT, the process
# counts and RAILS_LOG_TO_STDOUT; the server keeps the defaults below.

production = ENV['RAILS_ENV'] == 'production'
container  = !ENV['RAILS_LOG_TO_STDOUT'].to_s.empty? # plain Ruby: Puma reads this before Rails loads

tag 'puma-makeabox'
log_requests true
on_restart { puts 'restarting' }
worker_timeout 30
pidfile 'tmp/pids/puma.pid'

# In a container the logs stay on stdout for Cloud Logging, and nothing needs pumactl.
unless container
  # The control app is for pumactl on the server. Locally it would stop a second copy of the app from starting.
  activate_control_app 'tcp://127.0.0.1:9000/puma-ctl', no_token: true if production
  stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true
end

workers Integer(ENV.fetch('WEB_CONCURRENCY', production ? 8 : 2))
threads Integer(ENV.fetch('RAILS_MIN_THREADS', production ? 2 : 1)), Integer(ENV.fetch('RAILS_MAX_THREADS', production ? 4 : 1))

prune_bundler false
preload_app! true
port Integer(ENV.fetch('PORT', 3000))
