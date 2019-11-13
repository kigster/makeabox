# frozen_string_literal: true

bind "tcp://0.0.0.0:8899"
first_data_timeout 3
log_requests true
on_restart { puts 'Restarting' }

persistent_timeout "6"
pidfile 'tmp/pids/puma.pid'

port 3000
preload_app! true
rackup "#{Dir.pwd}/config.ru"
stdout_redirect 'log/puma.stdout', 'log/puma.stderr', false
threads 4, 9
worker_boot_timeout 30
worker_shutdown_timeout 60
worker_timeout 60
workers 10
