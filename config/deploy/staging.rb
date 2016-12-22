set :target_os, 'sunos'
require_relative '../../lib/capistrano/loader/os'

server 'kig.re', roles: %w{app db web worker}, user: 'kig'
set :ruby_version, '2.3.3'
