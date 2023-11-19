# frozen_string_literal: true

require 'capistrano/rbenv'

require 'capistrano/puma'
install_plugin Capistrano::Puma  # Default puma tasks
install_plugin Capistrano::Puma::Systemd

require 'capistrano/scm/git'
require 'capistrano/setup'
require 'airbrussh/capistrano'
require 'capistrano/deploy'
require 'capistrano/console'
require 'capistrano/bundler'
require 'capistrano/rails/assets'

require 'new_relic/recipes'

install_plugin Capistrano::SCM::Git

install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/**.cap').each { |r| import r }
