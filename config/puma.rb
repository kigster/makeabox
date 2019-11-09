root = Dir.getwd

tag                        'makeabox'
threads                    5, 10
workers                    2
log_requests               true
preload_app!(false)
bind                       "tcp://0.0.0.0:8899"
bind                       "tcp://0.0.0.0:3000"
pidfile                    'tmp/pids/puma.pid'
#stdout_redirect            'log/puma.stdout', 'log/puma.stderr', false
rackup "#{root}/config.ru"

