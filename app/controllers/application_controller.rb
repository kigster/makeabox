# frozen_string_literal: true

require 'makeabox/logger'
require 'makeabox/cache'
require 'makeabox/redis'

class ApplicationController < ActionController::Base
  include Makeabox::Logging

  cattr_accessor :generated_files

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  protected

  self.generated_files = Queue.new

  def not_cacheable!
    expires_now
  end
end
