# frozen_string_literal: true

require 'json'

class ApplicationController < ActionController::Base
  class << self
    attr_accessor :file_cleaner

    include Makeabox::WithLogging
  end

  self.file_cleaner = Makeabox::FileCleaner.configured_instance

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :reset_session

  include Makeabox::WithLogging
  include Makeabox::Cacheable
end
