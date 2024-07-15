# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.development.smtp.default_from,
          reply_to: Rails.application.credentials.development.smtp.default_from

  layout "mailer"
end
