
tag                        'makeabox'
threads                    4, 10
workers                    5
log_requests               true

preload_app!

bind                       "tcp://0.0.0.0:{{cfg.port}}"
pidfile                    '{{pkg.svc_var_path}}/tmp/puma.pid'

stdout_redirect            '{{pkg.svc_var_path}}/log/puma.stdout', '{{pkg.svc_var_path}}/log/puma.stderr', true

on_restart do
  puts 'Restarting'
end

worker_timeout 600
