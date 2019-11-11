# frozen_string_literal: true

source 'https://rubygems.org'

gem 'pg'

gem 'activerecord', '~> 6'
gem 'babel-transpiler'
gem 'colored2'
gem 'config'
gem 'haml'
gem 'jbuilder'
gem 'rails', '~> 6'
gem 'sass-rails', git: 'https://github.com/rails/sass-rails', branch: 'master'
gem 'sprockets', git: 'https://github.com/rails/sprockets', branch: 'master'
gem 'sprockets-rails', git: 'https://github.com/rails/sprockets-rails', branch: 'master'
gem 'tty-logger'
gem 'tzinfo-data'
gem 'uuid'
gem 'ruby-units', require: 'ruby_units/namespaced'
gem 'devise'
gem 'omniauth-google'

gem 'puma'

gem 'hiredis', platform: :mri
gem 'redis'

gem 'sdoc', group: :doc
# gem 'laser-cutter', '= 1.0.3'
gem 'laser-cutter', path: '../laser-cutter'
gem 'rb-fsevent'

# Monitoring
gem 'ddtrace'
gem 'dogapi'
gem 'newrelic_rpm'

gem 'dalli'
gem 'sidekiq'
gem 'sidekiq-pool'
gem 'sidekiq-unique-jobs'

group :development do
  gem 'airbrussh', require: false
  gem 'annotate',  git: 'https://github.com/ctran/annotate_models.git'
  gem 'awesome_print'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'relaxed-rubocop'
  gem 'rubocop'
  gem 'rubocop-performance'
end

group :test, :development, :demo do
  gem 'factory_bot'
  gem 'foreman'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'simplecov'
  # gem 'database_cleaner-active_record',
  #     git: 'https://github.com/databasecleaner/database_cleaner-active_record.git'
end
