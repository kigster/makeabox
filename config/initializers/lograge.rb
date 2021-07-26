# frozen_string_literal: true
require 'lograge'

Rails.application.configure do
  config.lograge.enabled   = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging  = false
  config.lograge.logger    = ActiveSupport::Logger.new(File.join(Rails.root, 'log', "#{Rails.env}.log"))

  config.lograge.custom_options =
    lambda do |event|
      {
        ddsource: 'ruby',
        ip: event.payload[:request].remote_ip,
        params: event.payload[:params].reject { |k| %w[controller action].include? k }
      }
    end
end
