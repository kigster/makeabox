
tag 'makabox'
threads 4, 16
workers 4
preload_app!
environment 'production'
daemonize false
bind "tcp://0.0.0.0:8899"
bind "tcp://0.0.0.0:3000"

pidfile 'tmp/puma.pid'

stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true

on_restart do
  puts 'Restarting'
end

worker_timeout 300
