# frozen_string_literal: true

class ApplicationController < ActionController::Base
  MUTEX = Mutex.new.freeze

  include MakeABox::Logging::ControllerHelpers
  around_action :log_incoming_request

  cattr_accessor :temp_files

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :reset_session

  protected

  self.temp_files = Queue.new

  def not_cacheable!
    expires_now
  end

  def logging(message)
    t1 = Time.now
    result = yield
    t2 = Time.now - t1
    Rails.logger.info(message + format(', elapsed %.4f(ms)', t2 * 1000))
    result
  end
end
