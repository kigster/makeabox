# frozen_string_literal: true

require 'json'

class ApplicationController < ActionController::Base
  class << self
    attr_accessor :file_cleaner

    include Makeabox::WithLogging
  end

  self.file_cleaner = Makeabox::FileCleaner.new

  include Makeabox::WithLogging

  MUTEX = Mutex.new.freeze

  # include Makeabox::Logging::ControllerHelpers
  # around_action :log_incoming_request

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :reset_session

  protected

  def garbage_collect(file)
    ApplicationController.file_cleaner << file
  end

  def not_cacheable!
    expires_now
  end

  def append_info_to_payload(payload)
    super
    payload[:level] =
      case payload[:status]
      when 200
        'INFO'
      when 302
        'WARN'
      else
        'ERROR'
      end
  end

  private


  # def garbage_collect_pdf(file)
  #   Thread.new do
  #     sleep SECONDS_TO_KEEP
  #     fs = File::Stat.new(file)
  #     age = Time.now.to_f - fs.ctime.to_f
  #     logging('garbage collecting', file: file, age: age) do |extra|
  #       if File.exist?(file)
  #         extra[:message] += ", removing it..."
  #         FileUtils.rm_f(file)
  #       else
  #         extra[:message] += ", hmm, it was already removed."
  #       end
  #     end
  #   end
  # end

end
