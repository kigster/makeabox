# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w[application.css application.js]

require 'sprockets/babel_processor'
Rails.application.config.assets.configure do |env|
  babel = Sprockets::BabelProcessor.new(
    'moduleIds' => true
  )
  env.register_transformer 'application/ecmascript-6', 'application/javascript', babel
end

Makeabox::Application.configure do
  config.sass.preferred_syntax = :sass
  config.sass.line_comments = false
  config.sass.cache = true
end
