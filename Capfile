# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

require 'capistrano/scm/git'

install_plugin Capistrano::SCM::Git

require 'capistrano/rbenv'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/puma'
require 'capistrano/service'
require 'capistrano/newrelic'
require 'capistrano/maintenance'

# Default puma tasks
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd
# install_plugin Capistrano::Puma, load_hooks: false  # Default puma tasks without hooks

# require 'capistrano/sidekiq'
# install_plugin Capistrano::Sidekiq
# install_plugin Capistrano::Sidekiq::Systemd

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/**.cap').each { |r| import r }
