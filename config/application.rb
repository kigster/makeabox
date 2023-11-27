# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

require 'sprockets/railtie'
require 'newrelic_rpm' if Rails.env.production?
require 'etc'
require 'haml'
require 'lograge'

require_relative '../lib/makeabox'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Makeabox
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1
    config.active_job.queue_adapter = :sidekiq
    #
    # nil will use the "default" queue
    # some of these options will not work with your Rails version
    # add/remove as necessary
    # config.action_mailer.deliver_later_queue_name = nil # defaults to "mailers"
    # config.action_mailbox.queues.routing    = nil       # defaults to "action_mailbox_routing"
    # config.active_storage.queues.analysis   = nil       # defaults to "active_storage_analysis"
    # config.active_storage.queues.purge      = nil       # defaults to "active_storage_purge"
    # config.active_storage.queues.mirror     = nil       # defaults to "active_storage_mirror"
    # config.active_storage.queues.purge    = :low      # alternatively, put purge jobs in the `low` queue

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks capistrano))
    autoload :Post, Rails.root.join('app/models/post.rb')
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Pacific Time (US & Canada)"
    config.eager_load_paths << Rails.root.join("lib")
    config.eager_load_paths << Rails.root.join("app/workers")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.assets.precompile += %w[**.ttf]

    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec
    end
  end
end
