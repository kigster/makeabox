# config valid only for Capistrano 3.1
# lock '3.1.0'

# Standard Flow:

# deploy
#   deploy:starting
#     [before]
#       deploy:ensure_stage
#       deploy:set_shared_assets
#     deploy:check
#   deploy:started
#   deploy:updating
#     git:create_release
#     deploy:symlink:shared
#   deploy:updated
#     [before]
#       deploy:bundle
#     [after]
#       deploy:migrate
#       deploy:compile_assets
#       deploy:normalize_assets
#   deploy:publishing
#     deploy:symlink:release
#   deploy:published
#   deploy:finishing
#     deploy:cleanup
#   deploy:finished
#     deploy:log_revision

require 'colored2'

set :application, 'makeabox'
set :repo_url, 'git@github.com:kigster/MakeABox.git'

set :bundle_flags, '--jobs=8 --deployment'
set :bundle_without, 'development test'
set :bundle_env_variables, { nokogiri_use_system_libraries: 1 }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :user_home, '/home/kig'
set :deploy_to, "#{fetch(:user_home)}/apps/makeabox"
set :ruby_bin_dir, "#{fetch(:user_home)}/.rbenv/versions/#{fetch(:ruby_version)}/bin"
set :rbenv, "#{fetch(:user_home)}/.rbenv/bin/rbenv"

# Default value for :format is :pretty
set :format, :pretty
set :log_level, :info
set :pty, true

set :ssh_options, {
   keys: %w(/Users/kig/.ssh/id_rsa),
   forward_agent: false,
   auth_methods: %w(publickey)
}

# set :linked_files, %w{config/database.yml}
# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pdfs tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

before 'bundler:install', 'ruby:bundler:install'
before 'deploy:starting', 'os:packages' if ENV['UPDATE_SYSTEM']

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'unicorn:stop'
      invoke 'unicorn:start'
    end
  end

  after :publishing, :restart
  after :restart, 'unicorn:restart'
  # ensure OS-specifc init script exists, so that reboots are OK
  after :finished, 'os:unicorn:init'

end

