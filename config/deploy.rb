# frozen_string_literal: true

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

set :datadog_api_key, ENV['DATADOG_API_KEY']
set :application, 'makeabox'
set :repo_url, 'git@github.com:kigster/make-a-box.io.git'
set :branch, `bash -c "source ~/.bashmatic/init.sh; git.branch.current"`
set :bundle_flags, '--jobs=8 --deployment'
set :bundle_without, 'development,test'
set :bundle_env_variables, { nokogiri_use_system_libraries: 1 }
set :branch, 'master'

set :user_home, '/home/kig'
set :deploy_to, "#{fetch(:user_home)}/apps/makeabox"

# Default value for :format is :pretty
set :format, :airbrussh
set :log_level, :info

set :rbenv_type, :system
set :ruby_version, File.read('.ruby-version').strip
set :encryption_key, File.read('.key').strip
set :rbenv_map_bins, %w[rake gem bundle ruby rails puma]
set :rbenv_roles, :all # default value
set :rbenv_ruby, fetch(:ruby_version)
set :native_gems, %i[nokogiri]
set :ruby_bin_dir, "#{fetch(:user_home)}/.rbenv/shims"

set :ssh_options, {
  keys: %W[#{Dir.home}/.ssh/id_rsa #{Dir.home}/.ssh/makeabox.pem #{Dir.home}/.ssh/aws.reinvent1.pem],
  forward_agent: false,
  auth_methods: %w[publickey]
}

set :puma_service_unit_name, 'puma.service'
set :linked_files, %w[config/secrets.yml]
set :linked_dirs, %w[bin log tmp/pdfs tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]
set :default_env, {}

# Default value for keep_releases is 5
set :keep_releases, 5

before 'bundler:install', 'ruby:bundler:native_config'

namespace :deploy do
  before :starting, 'deploy:setup'
  namespace(:assets) { after :precompile, 'deploy:permissions' }
  after :publishing, 'deploy:secrets:decrypt'
end
