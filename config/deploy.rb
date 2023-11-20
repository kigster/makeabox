# frozen_string_literal: true

set :application, 'makeabox'
set :user, 'ubuntu'

set :ssh_options, {
  auth_methods: %w[publickey],
  forward_agent: true,
  user: fetch(:user),
  keys: %W[#{Dir.home}/.ssh/id_ed25519 #{Dir.home}/.ssh/makeabox.pem], # #{Dir.home}/.ssh/aws.reinvent1.pem
}

server "makeabox.io",
       user: fetch(:user),
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

before 'bundler:install', 'ruby:bundler:native_config'
after 'deploy:updated', 'newrelic:notice_deployment'
before 'puma:restart', 'systemd:daemon-reload'
after 'puma:restart', 'systemd:status'

namespace :deploy do
  before :starting, 'deploy:setup'
  namespace(:assets) { after :precompile, 'deploy:permissions' }
  after :publishing, 'deploy:secrets:decrypt'
end

#
# set :application, Makeabox::NAME
# set :deploy_user, 'deploy'
#
# # setup repo details
# set :scm, :git
# set :repo_url, 'git@github.com:kigster/makeabox.git'
#
# # how many old releases do we want to keep
# set :keep_releases, 5
#
# # files we want symlinking to specific entries in shared.
# set :linked_files, %w{config/database.yml}
#
# # dirs we want symlinking to shared
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
#
# # what specs should be run before deployment is allowed to
# # continue, see lib/capistrano/tasks/run_tests.cap
# set :tests, []
#
# # which config files should be copied by deploy:setup_config
# # see documentation in lib/capistrano/tasks/setup_config.cap
# # for details of operations
# set(:config_files, %w(
#       nginx.conf
#       database.example.yml
#       log_rotation
#       monit
#       unicorn.rb
#       unicorn_init.sh
#     ))
#
# # which config files should be made executable after copying
# # by deploy:setup_config
# set(:executable_config_files, %w(
#       unicorn_init.sh
#     ))
#
# # files which need to be symlinked to other parts of the
# # filesystem. For example nginx virtualhosts, log rotation
# # init scripts etc.
# set(:symlinks, [
#   {
#     source: "nginx.conf",
#     link: "/etc/nginx/sites-enabled/#{fetch(:full_app_name)}"
#   },
#   {
#     source: "unicorn_init.sh",
#     link: "/etc/init.d/unicorn_#{fetch(:full_app_name)}"
#   },
#   {
#     source: "log_rotation",
#     link: "/etc/logrotate.d/#{fetch(:full_app_name)}"
#   },
#   {
#     source: "monit",
#     link: "/etc/monit/conf.d/#{fetch(:full_app_name)}.conf"
#   }
# ])
#
# # this:
# # http://www.capistranorb.com/documentation/getting-started/flow/
# # is worth reading for a quick overview of what tasks are called
# # and when for `cap stage deploy`
#
# namespace :deploy do
#   # make sure we're deploying what we think we're deploying
#   before :deploy, "deploy:check_revision"
#   # only allow a deploy with passing tests to deployed
#   before :deploy, "deploy:run_tests"
#   # compile assets locally then rsync
#   after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
#   after :finishing, 'deploy:cleanup'
#
#   # remove the default nginx configuration as it will tend
#   # to conflict with our configs.
#   before 'deploy:setup_config', 'nginx:remove_default_vhost'
#
#   # reload nginx to it will pick up any modified vhosts from
#   # setup_config
#   after 'deploy:setup_config', 'nginx:reload'
#
#   # Restart monit so it will pick up any monit configurations
#   # we've added
#   after 'deploy:setup_config', 'monit:restart'
#
#   # As of Capistrano 3.1, the `deploy:restart` task is not called
#   # automatically.
#   after 'deploy:publishing', 'deploy:restart'
# end
