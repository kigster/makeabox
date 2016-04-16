# config/unicorn.rb
require 'colored2'
worker_processes 16
timeout 15
preload_app true
listen "*:8899", :tcp_nopush => true, :backlog => 64

app_shared_root = if ENV['RAILS_ENV'] == 'production'
  '/home/kig/apps/makeabox/shared'
else
  File.expand_path('../../', __FILE__)
end

puts "━━━━━━━━".yellow + " app root is set to ".green + "━━━━━━━━━┫".yellow + " #{app_shared_root} ".blue + "┣━".yellow

pid "#{app_shared_root}/tmp/pids/unicorn.pid"
stderr_path "#{app_shared_root}/log/unicorn.stderr.log"
stdout_path "#{app_shared_root}/log/unicorn.stdout.log"


before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
