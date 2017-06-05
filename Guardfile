#!/usr/bin/env ruby -W0
#^syntax detection

# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require 'guard/rspec'

guard :rspec,
      cmd:            'bundle exec rspec',
      all_after_pass: false,
      all_on_start:   false do

  watch(%r{Gemfile}) { 'spec' }
  watch(%r{^lib/(.+)\.rb$}) { 'spec' }
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb') { 'spec' }
  watch(%r{spec/support/.*}) { 'spec' }
  watch(%r{spec/javascript/.*}) { 'teaspoon' }
end

guard :teaspoon do
  watch(%r{^app/assets/javascripts/(.+)\.js}) { |m| "#{m[1]}_spec" }
  watch(%r{^spec/javascripts/.+$})
end
