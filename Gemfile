# frozen_string_literal: true

source 'https://rubygems.org'

group :default do
  gem 'awesome_print'
  gem 'bcrypt_pbkdf'
  gem 'bootsnap'
  gem 'colored2'
  gem 'connection_pool'
  gem 'dalli'
  gem 'ed25519'
  gem 'haml'
  gem 'importmap-rails'
  # Lids are merged but not on RubyGems yet; once 2.0.1 is released, go back to '~> 2.0', '>= 2.0.1'.
  gem 'laser-cutter', github: 'kigster/laser-cutter', ref: 'bf2b831'
  gem 'lograge'
  gem 'matrix'
  gem 'newrelic_rpm'
  gem 'propshaft'
  gem 'puma', '~> 6'
  gem 'rack-timeout', require: 'rack/timeout/base'
  gem 'rails', '~> 8.1'
  gem 'sdoc', group: :doc
  gem 'sidekiq'
  gem 'stimulus-rails'
  gem 'sym'
  gem 'tzinfo-data'
  gem 'yard', require: false
end

group :development do
  gem 'airbrussh'
  gem 'asciidoctor'
  gem 'capistrano'
  # gem 'capistrano3-puma', github: "seuros/capistrano-puma"
  gem 'capistrano-maintenance', '~> 1.2', require: false
  gem 'capistrano-newrelic'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-service'
  gem 'capistrano-sidekiq'
  gem 'solargraph'
end

group :test, :development do
  gem 'codecov'
  gem 'mry', require: false
  gem 'relaxed-rubocop'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rspec-rake'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rufo', require: false
  gem 'simplecov'
  gem 'yard-rspec', require: false
end
