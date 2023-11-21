# frozen_string_literal: true

class PdfGeneratorJob
  include Sidekiq::Job

  def perform(*args)
    # Do something
  end
end
