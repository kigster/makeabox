at_exit do
  until ApplicationController.temp_files.empty?
    file = ApplicationController.temp_files.pop
    warn "Unlinking file #{file}...."
    File.unlink(file)
  end
end
