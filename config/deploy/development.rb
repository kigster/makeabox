# frozen_string_literal: true

# OVERRIDE PRODUCTION RUBY HERE
# set :ruby_version, File.read('.ruby-version').strip
set :target_os, 'darwin'
set :rails_env, 'development'

require_relative '../../lib/capistrano/loader/os'

server 'localhost', roles: %w[app db web worker], user: 'kig', sudo: true
set :gem_config, {}
