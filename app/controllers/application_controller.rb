# frozen_string_literal: true

require 'json'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  class << self
    attr_accessor :file_cleaner

    include Makeabox::WithLogging
  end

  self.file_cleaner = Makeabox::FileCleaner.configured_instance

  include Makeabox::WithLogging
  include Makeabox::Cacheable
end
