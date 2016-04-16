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

set :ruby_version, '2.3.0'
set :user_home, '/home/kig'
set :deploy_to, "#{fetch(:user_home)}/apps/makeabox"
set :ruby_bin_dir, "#{fetch(:user_home)}/.rbenv/versions/#{fetch(:ruby_version)}/bin"
set :rbenv, "#{fetch(:user_home)}/.rbenv/bin/rbenv"

# Default value for :format is :pretty
#set :format, :pretty
set :format, :pretty
set :log_level, :debug
set :pty, true

# set :target_os, 'SunOS'
set :target_os, 'Linux'


# set :linked_files, %w{config/database.yml}
# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pdfs tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

if fetch(:target_os).eql?('SunOS')
  set :default_env, { PATH:            "#{fetch(:ruby_bin_dir)}:/opt/local/bin:$PATH",
                      MAKE_OPTS:       '-j48',
                      LD_LIBRARY_PATH: '/opt/local/lib',
                      LDFLAGS:         '-L/opt/local/lib -R/opt/local/lib',
                      CFLAGS:          '-I/opt/local/include'
  }
  set :packages, %w(
    git
    gcc49
    gmake
    libiconv
    libxml2
    libxslt
    openssl
    watch
    zlib
    tar
    nodejs
  )
else
  set :default_env, { PATH:            "#{fetch(:ruby_bin_dir)}:/opt/local/bin:$PATH",
                      MAKE_OPTS:       '-j48'
  }
  set :packages, %w(
    build-essential
    gcc
    git
    git-core
    htop
    libbz2-dev
    libffi-dev
    libmagickwand-dev
    libmemcached-dev
    libpq-dev
    libreadline-dev
    libssl-dev
    make
    pgbouncer
    postgresql-client
    wget
    curl
    zlib1g-dev
    libcurl4-openssl-dev
    libxml2-dev
    libxslt1-dev
    libyaml-dev
    nodejs
  )
end

puts Dir.pwd
eval File.read("lib/capistrano/tasks/os/#{fetch(:target_os).downcase}.cap")

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

end
