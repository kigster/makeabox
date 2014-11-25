class ApplicationController < ActionController::Base
  cattr_accessor :temp_files
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  protected

  self.temp_files = Queue.new

  def not_cacheable!
    expires_now
  end

  def logging(message, &block)
    t1 = Time.now
    result = yield
    t2 = Time.now - t1
    Rails.logger.info(message + sprintf(", elapsed %.4f(ms)", t2 * 1000))
    result
  end
end
