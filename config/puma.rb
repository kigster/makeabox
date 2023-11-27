# frozen_string_literal: true

rails_env = ENV.fetch('RAILS_ENV', 'development')

tag 'puma-makeabox'
log_requests true
activate_control_app 'tcp://127.0.0.1:9000/puma-ctl', no_token: true
pidfile 'tmp/pids/puma.pid'
stdout_redirect "log/#{rails_env}.log", "log/#{rails_env}.log", true
on_restart { puts 'restarting' }
worker_timeout 30

if rails_env == 'production'
  workers 9
  threads 4, 4
else
  workers 3
  threads 1, 2
end

preload_app! true
prune_bundler true
port 3000
