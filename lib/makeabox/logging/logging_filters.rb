# frozen_string_literal: true

require 'colored2'
require 'logger'
require 'yaml'
require 'digest'

module MakeABox
  module Logging

    # This module loads a YAML into a Hash, which contains a mapping between
    # Rails environments, and a list of filters (regular expressions) that,
    # if they match the incoming log messages, are then rejected.
    module LoggingFilters
      class << self
        attr_accessor :config

        def load_config!
          self.config = defined?(::Rails) ?
                          YAML.load(File.read(Rails.root + 'config/logging_filters.yml')) :
                          YAML.load(File.read(File.expand_path('../../../config/logging_filters.yml', __dir__)))
        end

        def all_filters
          config['filters']
        end

        def active_filters
          config[::MakeABox::Logging.detect_rails_env]['filters'].map do |filter_name|
            all_filters[filter_name]
          end
        end
      end
    end

    LoggingFilters.load_config!
  end
end
