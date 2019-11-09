set :ruby_version, '2.6.5'
set :target_os, 'linux'
set :rails_env, 'staging'

require_relative '../../lib/capistrano/loader/os'

server 'apollo.re1.re', roles: %w{app db web worker}, user: 'kig', sudo: true
set :gem_config, {}
