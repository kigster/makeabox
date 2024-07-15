# frozen_string_literal: true

class ApplicationController < ActionController::Base
  cattr_accessor :temp_files
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    new_boxes_path
  end

  def after_sign_out_path_for(resource)
    root_path
  end

  self.temp_files = Queue.new

  def not_cacheable!
    expires_now
  end

  def logging(message)
    t1     = Time.now
    result = yield
    t2     = Time.now - t1
    Rails.logger.info(message + sprintf(", elapsed %.4f(ms)", t2 * 1000))
    result
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :first, :last])
  end
end
