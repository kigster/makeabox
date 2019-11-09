
directory                  "/usr/src/app"
daemonize                  false
threads                    5, 10
workers                    5
worker_timeout             60
log_requests               true
port                       5001
pidfile                    "/usr/src/app/tmp/pids/puma.pid"
tag                        "makeabox"
rackup                     "/usr/src/app/config.ru"
preload_app!               false
raise_exception_on_sigterm true

environment ENV["RAILS_ENV"] || "development"

#stdout_redirect(stdout = "/dev/stdout", stderr = "/dev/stderr", append = true)

