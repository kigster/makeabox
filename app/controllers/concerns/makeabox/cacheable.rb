# frozen_string_literal: true

module Makeabox
  # Module providing cache key generation and related utilitiess
  module Cacheable
    extend ActiveSupport::Concern

    included do
      protected

      def create_cache_key(key)
        revision =
          if File.exist?('REVISION')
            File.read('REVISION')
          else
            git_rev_parse
          end
        "#{key}.#{revision}"
      end

      def git_rev_parse
        `git rev-parse --verify HEAD`.chomp
      end

      def garbage_collect(file)
        ApplicationController.file_cleaner << file
      end

      def not_cacheable!
        expires_now
      end
    end
  end
end
