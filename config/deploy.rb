# frozen_string_literal: true

set :application, 'makeabox'
set :user, 'ubuntu'

set :ssh_options, {
  auth_methods:  %w[publickey],
  forward_agent: true,
  user:          fetch(:user),
  keys:          %W[#{Dir.home}/.ssh/id_ed25519 #{Dir.home}/.ssh/makeabox.pem], # #{Dir.home}/.ssh/aws.reinvent1.pem
}

server "makeabox.io",
       user:  fetch(:user),
       roles: %w[web app]

set :repo_url, 'git@github.com:kigster/makeabox.git'
set :branch, 'main'
set :bundle_flags, '--jobs=8 --without development,test'
set :bundle_env_variables, { nokogiri_use_system_libraries: 1 }

set :user_home, '/home/kig'
set :deploy_to, "#{fetch(:user_home)}/apps/makeabox"

# Default value for :format is :pretty
set :format, :airbrussh
set :log_level, :info

set :rbenv_type, :user
set :ruby_version, File.read('.ruby-version').strip
unless File.exist?('.key')
  abort 'You must provide a .key file with the encryption key for secrets.yml'
end
set :encryption_key, File.read('.key').strip
set :rbenv_map_bins, %w[rake gem bundle ruby rails puma]
set :rbenv_ruby, fetch(:ruby_version)
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails puma}
set :rbenv_roles, :all # default value
set :native_gems, %i[nokogiri]
set :ruby_bin_dir, "#{fetch(:user_home)}/.rbenv/shims"

set :puma_service_unit_name, 'puma.makeabox.service'
set :linked_files, %w[config/secrets.yml]
set :linked_dirs, %w[bin log tmp/pdfs tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]
set :default_env, {}

# New Relic Application Name to deploy to.  Default to :application if no value set
set :newrelic_appname, "MakeABox"
set :newrelic_env, fetch(:stage, fetch(:rack_env, fetch(:rails_env, 'production')))
set :newrelic_deploy_user, fetch(:user)

set :maintenance_template_path, File.expand_path('../app/views/system/maintenance.html.erb', __dir__)

before 'bundler:install', 'ruby:bundler:native_config'
after 'deploy:updated', 'newrelic:notice_deployment'
before 'puma:restart', 'systemd:daemon-reload'
after 'puma:restart', 'systemd:restart'
after 'systemd:restart', 'systemd:status'
after 'systemd:status', 'maintenance:disable'

namespace :deploy do
  before :starting, 'deploy:setup'
  namespace(:assets) { after :precompile, 'deploy:permissions' }
  after :publishing, 'deploy:secrets:decrypt'
end
