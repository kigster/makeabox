# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

require 'newrelic_rpm' if Rails.env.production?
require 'etc'
require 'yaml'
require 'haml'
require 'lograge'
require_relative '../lib/makeabox'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Makeabox
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks capistrano])

    config.time_zone = 'Pacific Time (US & Canada)'

    # Rails no longer reads config/secrets.yml, but the deploy still ships one
    # (see lib/capistrano/tasks/secrets.cap), so the key is read from it here.
    secrets_file = Rails.root.join('config/secrets.yml')
    if ENV['SECRET_KEY_BASE'].blank? && secrets_file.exist?
      config.secret_key_base = YAML.safe_load_file(secrets_file, aliases: true).dig(Rails.env, 'secret_key_base')
    end

    # Design sources, not something to publish.
    config.assets.excluded_paths << Rails.root.join('app/assets/photoshop')

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec
    end
  end
end
