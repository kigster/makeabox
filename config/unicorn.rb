# config/unicorn.rb
worker_processes 16
timeout 15
preload_app true
listen '*:8899', tcp_nopush: true, backlog: 64

REMOTE_SHARED_DIR = '/home/kig/apps/makeabox/shared'.freeze
app_shared_root = if ENV['RAILS_ENV'] == 'production' && Dir.exist?(REMOTE_SHARED_DIR)
                    REMOTE_SHARED_DIR
                  else
                    File.expand_path('..', __dir__)
end

pid "#{app_shared_root}/tmp/pids/unicorn.pid"
stderr_path "#{app_shared_root}/log/unicorn.stderr.log"
stdout_path "#{app_shared_root}/log/unicorn.stdout.log"

before_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
