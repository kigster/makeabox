module MakeABox
  module Middleware
    class TempFileCleaner

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        response = app.call(env)
        clean_files!
        response
      end

      def clean_files!
        t = Thread.new do
          if f = ApplicationController.temp_files.pop
            begin
              sleep 10
              Rails.logger.warn("Deleting file #{f}...")
              File.delete(f)
            rescue Exception => e
              Rails.logger.error(e.backtrace.join "\n")
              raise e
            end
          end
        end
      end
    end
  end
end
