# frozen_string_literal: true

tag 'makeabox.app'
workers 7
log_requests true
activate_control_app 'tcp://127.0.0.1:9000/puma-ctl', no_token: true
pidfile 'tmp/pids/puma.pid'
stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true
on_restart { puts 'restarting' }
on_worker_shutdown { puts 'worker shutting down...' }
worker_timeout 30

if ENV['RAILS_ENV'] == 'production'
  threads 2, 4
  prune_bundler true
  preload_app! false
  port 8899
else
  threads 1, 1
  prune_bundler false
  preload_app! true
  port 3000
end
