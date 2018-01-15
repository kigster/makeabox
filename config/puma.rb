
tag                        'makabox'
threads                    4, 32 
workers                    3
log_requests               true

preload_app!

bind                       "tcp://0.0.0.0:8899"
bind                       "tcp://0.0.0.0:3000"
pidfile                    'tmp/pids/puma.pid'

stdout_redirect            'log/puma.stdout', 'log/puma.stderr', true

on_restart do
  puts 'Restarting'
end

worker_timeout 400
