at_exit do
  until ApplicationController.temp_files.empty? do
    file = ApplicationController.temp_files.pop
    STDERR.puts "Unlinking file #{file}...."
    File.unlink(file)
  end
end
