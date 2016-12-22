set :target_os, 'linux'
require_relative '../../lib/capistrano/loader/os'

server 'app101.dev.nvnt.re', roles: %w{app db web worker}, user: 'kig'
set :ruby_version, '2.3.0'

