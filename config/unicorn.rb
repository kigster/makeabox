# config/unicorn.rb
worker_processes 16
timeout 15
preload_app true
listen "*:23432", :tcp_nopush => true, :backlog => 64
app = '/home/kig/makeabox'

pid "#{app}/shared/tmp/unicorn.pid"
stderr_path "#{app}/shared/log/unicorn.stderr.log"
stdout_path "#{app}/shared/log/unicorn.stdout.log"

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
