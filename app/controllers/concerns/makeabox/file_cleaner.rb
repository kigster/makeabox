# frozen_string_literal: true
require 'forwardable'
require 'singleton'

module Makeabox
  # This class maintains a single global thread per Ruby Process that cleans up old PDFs
  # generated by makeabox controller
  class FileCleaner
    include Singleton
    include WithLogging

    class << self
      def configured_instance
        instance.tap do |cleaner|
          # do initialize it once
          cleaner.configure! unless cleaner.configured
        end
      end
    end

    SECONDS_TO_KEEP  = 60 # we'll delete local files after this many seconds
    SECONDS_TO_SLEEP = 30

    attr_accessor :thread, :temp_files, :configured

    extend Forwardable
    def_delegators :@temp_files, :size, :<<, :pop, :empty?

    def configure!
      return if configured

      self.temp_files = Queue.new
      self.thread     =
        Thread.new do
          loop do
            gc! || sleep(SECONDS_TO_SLEEP)
          end
        end
      self.configured = true
    end

    def <<(file)
      temp_files << file
    end

    def gc!
      return if temp_files.empty?

      file = temp_files.pop
      return if file.nil?
      return unless File.exist?(file)

      fs  = File::Stat.new(file)
      age = Time.now.to_f - fs.ctime.to_f
      logging('garbage collecting file', file: file, age: age) do |extra|
        inspect_file(file, age, extra)
      end
    rescue StandardError => e
      Rails.logger.error('FileCleaner.gc!', error: e.message)
    end
  end
end
