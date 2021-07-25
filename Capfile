# frozen_string_literal: true

require 'dogapi'
require 'capistrano/datadog'
require 'new_relic/recipes'

set :datadog_api_key, '0e26092e9895a3b45bea2ed9d1effc44'

require 'capistrano/scm/git'

# Load DSL and Setup Up Stages
require 'airbrussh/capistrano'
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'
require 'capistrano/console'
require 'capistrano/bundler'
require 'capistrano/rails/assets'

install_plugin Capistrano::SCM::Git

require 'capistrano/rbenv'
require 'capistrano/puma'

install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/**.cap').each { |r| import r }
