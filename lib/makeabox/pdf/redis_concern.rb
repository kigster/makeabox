# frozen_string_literal: true

require 'hashie/mash'

module Makeabox
  module PDF
    module RedisConcern
      extend ActiveSupport::Concern

      included do
        def job_key
          @job_key ||= "job:#{job_id}"
        end

        def get_status(_job_id)
          with_redis do |redis|
            Hashie::Mash.new(redis.hgetall(job_key))
          end
        end

        def with_redis(&block)
          Makeabox.progress_redis.with(&block)
        end
      end
    end
  end
end
