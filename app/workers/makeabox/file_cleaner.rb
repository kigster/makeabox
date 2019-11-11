# frozen_string_literal: true

module Makeabox
  class FileCleaner
    include AbstractWorker

    sidekiq_options queue: 'deletion'

    def perform
      until ApplicationController.temp_files.empty?
        file = ApplicationController.temp_files.pop
        "Unlinking file #{file}...."
        File.unlink(file)
      end
    end
  end
end
