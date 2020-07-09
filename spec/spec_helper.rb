# frozen_string_literal: true

ENV['RUBYOPT'] = '-W0'

require 'rspec/core'
require 'rspec/its'
require 'simplecov'

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatters =
    SimpleCov::Formatter::MultiFormatter.new([
                                               SimpleCov::Formatter::HTMLFormatter,
                                               SimpleCov::Formatter::Codecov
                                             ])
end

SimpleCov.start 'rails'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!

  config.example_status_persistence_file_path = './tmp/rspec-examples.txt'

  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed
end
