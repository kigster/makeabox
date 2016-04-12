# config valid only for Capistrano 3.1
#lock '3.1.0'

set :application, 'makeabox'
set :repo_url, 'git@github.com:kigster/MakeABox.git'

set :bundle_flags, "--jobs=8 --deployment"
set :bundle_without,  "development test"
set :bundle_env_variables, { nokogiri_use_system_libraries: 1 }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :ruby_version, '2.3.0'
set :user_home, '/home/kig'
set :deploy_to, "#{fetch(:user_home)}/apps/makeabox"

# Default valu e for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
set :default_env, { path: "#{fetch(:user_home)}/.rbenv/versions/#{fetch(:ruby_version)}/bin:#{fetch(:user_home)}/.rbenv/bin:/opt/local/bin:$PATH", 'MAKE_OPTS' => '-j48' }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # invoke 'unicorn:stop'
      # invoke 'unicorn:start'
    end
  end

  after :publishing, :restart
  after :restart, 'unicorn:restart'

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
