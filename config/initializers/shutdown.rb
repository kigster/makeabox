# frozen_string_literal: true

at_exit do
  until ApplicationController.file_cleaner.empty?
    file = ApplicationController.temp_files.pop
    warn "Unlinking file #{file}...."
    begin
      FileUtils.rm_f(file)
    rescue IOError => e
      warn e.message
    end
  end
end
