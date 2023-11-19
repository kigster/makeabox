# frozen_string_literal: true

require 'capistrano/scm/git'
require 'capistrano/gem'
require 'capistrano/bundler'
require 'capistrano/puma'
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/console'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'airbrussh/capistrano'
require 'new_relic/recipes'

install_plugin Capistrano::Puma
isstall_plugin Capistrano::Puma::Systemd
install_plugin Capistrano::SCM::Git1

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/**.cap').each { |r| import r }
