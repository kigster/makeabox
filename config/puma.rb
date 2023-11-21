# frozen_string_literal: true

tag 'puma-makeabox'
log_requests true
activate_control_app 'tcp://127.0.0.1:9000/puma-ctl', no_token: true
pidfile 'tmp/pids/puma.pid'
stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true
on_restart { puts 'restarting' }
worker_timeout 30

if ENV['RAILS_ENV'] == 'production'
  workers 9
  threads 4, 4
else
  workers 1
  threads 1, 1
end
prune_bundler false
preload_app! true
port 3000
