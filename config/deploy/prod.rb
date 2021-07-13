# frozen_string_literal: true

set :ruby_version, '3.0.2'
set :target_os, 'linux'
set :rails_env, 'production'

require_relative '../../lib/capistrano/loader/os'

server 'makeabox.app', roles: %w[app db web worker], user: 'kig', sudo: true
set :gem_config, {}
