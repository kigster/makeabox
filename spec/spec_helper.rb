# frozen_string_literal: true

ENV['RUBYOPT'] = '-W0'

require 'rspec/core'
require 'rspec/its'
require 'simplecov'
require "coverage/badge"
require "fileutils"
require "stringio"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

SimpleCov.start "rails" do
  skip "/spec/"
  enable_coverage :line
  minimum_coverage 50

  self.formatters = [SimpleCov::Formatter::HTMLFormatter,
                     Coverage::Badge::Formatter]
end

SimpleCov.at_exit do
  SimpleCov.result.format!
  # rubocop: disable-next RSpec/Output
  puts "Coverage: #{SimpleCov.result.covered_percent.round(2)}%"
  FileUtils.mkdir_p("docs/badges")
  FileUtils.mv("coverage/badge.svg", "docs/badges/coverage_badge.svg")
end

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

