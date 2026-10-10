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
      secret = YAML.safe_load_file(secrets_file, aliases: true)&.dig(Rails.env, 'secret_key_base')
      if secret.blank? && Rails.env.production? && ENV['SECRET_KEY_BASE_DUMMY'].blank?
        raise 'config/secrets.yml has no production secret_key_base. Add one, or set SECRET_KEY_BASE.'
      end

      config.secret_key_base = secret if secret.present?
    end

    # In a container there is no secrets.yml. Without SECRET_KEY_BASE the app
    # would boot and then fail every request, health check included, so it
    # refuses to boot instead and the deploy fails where it can be seen.
    if Rails.env.production? && !secrets_file.exist? &&
       ENV.values_at('SECRET_KEY_BASE', 'SECRET_KEY_BASE_DUMMY', 'RAILS_MASTER_KEY').all?(&:blank?)
      raise 'Set SECRET_KEY_BASE: production has no secret key without it.'
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
