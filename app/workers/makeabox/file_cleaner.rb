module Makeabox
  class FileCleaner
    include AbstractWorker

    sidekiq_options queue: 'deletion'

    def perform
      until ApplicationController.temp_files.empty? do
        file = ApplicationController.temp_files.pop
        "Unlinking file #{file}...."
        File.unlink(file)
      end
    end
  end
end
