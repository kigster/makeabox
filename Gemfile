# frozen_string_literal: true

source 'https://rubygems.org'

gem 'MailchimpTransactional', '~> 1.0.59'
gem 'rack', '=2.2.9'
gem 'colored2'
gem 'config'
gem 'dalli'
gem 'devise'
gem 'haml'
gem 'haml-rails'
gem 'laser-cutter', '= 1.0.3'
gem 'matrix'
gem 'pg'
gem 'puma'
gem 'puma-status'
gem 'rb-fsevent'
gem 'redis'
gem 'ydoc', group: :doc
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'tty-logger'
gem 'uuid'

gem 'rails', '~> 7.1'
# replace sprockets with propshaft
gem 'propshaft'

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem 'jsbundling-rails'
# Hotwire"s SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire"s modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem 'cssbundling-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]
# Reduces oot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Monitoring
# gem 'ddtrace'
# gem 'dogapi'
gem 'newrelic_rpm'

group :development do
  gem 'annotate'
  gem 'airbrussh', require: false
  gem 'awesome_print'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-sidekiq'
  gem 'capistrano3-puma'
  gem 'rubocop'
  gem 'rubocop-performance'
end

group :test, :development, :demo do
  gem 'foreman'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
end
