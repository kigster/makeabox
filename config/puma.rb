# frozen_string_literal: true

tag 'puma-makeabox'
log_requests true
# The control app is for pumactl on the server. Locally it would stop a second copy of the app from starting.
activate_control_app 'tcp://127.0.0.1:9000/puma-ctl', no_token: true if ENV['RAILS_ENV'] == 'production'
pidfile 'tmp/pids/puma.pid'
stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true
on_restart { puts 'restarting' }
worker_timeout 30

if ENV['RAILS_ENV'] == 'production'
  workers 8
  threads 2, 4
else
  workers 2
  threads 1, 1
end
prune_bundler false
preload_app! true
port 3000
