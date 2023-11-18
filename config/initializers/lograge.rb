# frozen_string_literal: true

require 'lograge'

Rails.application.configure do
  config.lograge.enabled   = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging  = false
  config.lograge.logger    = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log").to_s)

  config.lograge.custom_options =
    lambda do |event|
      {
        ddsource: 'ruby',
        ip: event.payload[:request].remote_ip,
        params: event.payload[:params].reject { |k| %w[controller action].include? k }
      }
    end
end
