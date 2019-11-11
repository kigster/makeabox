# frozen_string_literal: true

require_relative '../lib/makeabox/logger'
root = Dir.getwd

tag                        'makeabox'
threads                    10, 20
workers                    10
log_requests               true

preload_app!               false

bind                       "tcp://0.0.0.0:8899"
bind                       "tcp://0.0.0.0:3000"
pidfile                    'tmp/pids/puma.pid'
rackup                     "#{root}/config.ru"

#stdout_redirect            'log/puma.stdout', 'log/puma.stderr', false
stdout_redirect             STDOUT, STDERR, false

on_restart { puts 'Restarting' }

worker_timeout             30

