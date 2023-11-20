# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Rails.application.load_tasks

if Rails.env.development?
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

task :doc do
  puts `bundle exec yardoc -o doc '{lib,app,config,spec}/**/*.rb' - README.adoc`
end

task :versions do
  puts "Version of the LaserCutter Library  :  #{Laser::Cutter::VERSION}"
  puts "Version of MakeABox.io Web Site   s  : #{Makeabox::VERSION}"
end
