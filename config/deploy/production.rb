set :ruby_version, '2.6.5'
set :target_os, 'linux'
set :rails_env, 'production'

require_relative '../../lib/capistrano/loader/os'

server 'kig.re', roles: %w{app db web worker}, user: 'kig', sudo: true
set :gem_config, {}

puts `bash -c "ssh-add ~/.ssh/aws.reinvent1.pem"` if File.exist?("#{Dir.home}/.ssh/aws.reinvent1.pem")

