# frozen_string_literal: true

tag 'makeabox.app'
threads 8, 8
workers 6
log_requests true
preload_app! false
activate_control_app 'tcp://127.0.0.1:9000/puma-ctl', no_token: true
port 8899
pidfile 'tmp/pids/puma.pid'
stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true

on_restart { puts 'restarting' }
on_worker_shutdown { puts 'worker shutting down...' }

worker_timeout 30
