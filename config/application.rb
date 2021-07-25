# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
require 'active_model/railtie'
# require "active_record/railtie"
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'
require 'newrelic_rpm' if Rails.env.production?
require 'etc'
require 'dalli'
require 'active_support/cache/dalli_store'
require 'action_dispatch/middleware/session/dalli_store'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MakeABox
  def self.live?
    Rails.env.production? && Etc.uname[:sysname] =~ /linux/i
  end

  VERSION = '2.0.0'

  MEMCACHED_CONFIG = {
    socket_timeout: 0.2,
    expires_in: 10.minute,
    keepalive: true,
    compress: true,
    pool_size: 10,
    pool_timeout: 30
  }.freeze

  MEMCACHED_PORT = ENV.fetch('MEMCACHED_PORT', 11_211)
  MEMCACHED_HOST = ENV.fetch('MEMCACHED_HOST', 'localhost')
  MEMCACHED_URL  = "#{MEMCACHED_HOST}:#{MEMCACHED_PORT}"

  def self.memcached_options(namespace = nil)
    opts ||= {}
    namespace ||= ''
    namespace = namespace.to_s
    namespace += ".#{Rails.env}"
    MEMCACHED_CONFIG.dup.merge(opts.merge({ namespace: namespace }))
  end

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Be sure to restart your server when you modify this file.
    # config/application.rb
    # config.middleware.delete ActionDispatch::Cookies
    # config.middleware.delete ActionDispatch::Session::CookieStore
    # config.middleware.delete ActionDispatch::Flash

    config.assets.precompile += %w[**.ttf]

    config.generators do |g|
      g.template_engine :haml

      # you can also specify a different test framework or ORM here
      g.test_framework  :rspec
      # g.orm             :mongoid
    end
  end
end
