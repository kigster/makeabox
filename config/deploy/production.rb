# frozen_string_literal: true

# OVERRIDE PRODUCTION RUBY HERE
# set :ruby_version, File.read('.ruby-version').strip
set :target_os, 'linux'
set :rails_env, 'production'

require_relative '../../lib/capistrano/loader/os'

server 'makeabox.io', roles: %w[app db web worker], user: 'kig', sudo: true
set :gem_config, {}
