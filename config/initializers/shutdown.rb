# frozen_string_literal: true

at_exit do
  include Makeabox::WithLogging
  cleaner = ApplicationController.file_cleaner
  while cleaner.present?
    file = cleaner.pop
    logging('Shutdown Vacuum:', file: file) do |extra|
      FileUtils.rm_f(file)
      extra[:message] += ' [✔] removed'
    rescue IOError => e
      extra[:message] += ", error: #{e.message}"
    end
  end
end
