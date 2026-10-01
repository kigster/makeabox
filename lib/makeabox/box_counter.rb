# frozen_string_literal: true

module Makeabox
  # Counts the boxes downloaded since makeabox began, in Redis.
  #
  #   Makeabox::BoxCounter.record_download('pdf')  # => 1_300_001
  #   Makeabox::BoxCounter.total                   # => 1_300_001
  #
  # The count starts at STARTING_TOTAL, the boxes downloaded before it was
  # kept in Redis. A stopped Redis never holds up a download: recording is
  # skipped and the total reads as nil, which the page shows as dashes.
  class BoxCounter
    DOWNLOADS_KEY = 'box_downloads'
    STARTING_TOTAL = 1_300_000

    class << self
      # @return [Integer, nil] the new total, or nil when Redis is unavailable
      def record_download(format)
        REDIS.with do |redis|
          redis.set(DOWNLOADS_KEY, STARTING_TOTAL, nx: true)
          total = redis.incr(DOWNLOADS_KEY)
          series(redis, format)
          total
        end
      rescue Redis::BaseError, ConnectionPool::TimeoutError => e
        Rails.logger.warn("box counter failed: #{e.message}")
        nil
      end

      # @return [Integer, nil] nil when Redis is unavailable
      def total
        REDIS.with { |redis| redis.get(DOWNLOADS_KEY)&.to_i || STARTING_TOTAL }
      rescue Redis::BaseError, ConnectionPool::TimeoutError => e
        Rails.logger.warn("box counter unavailable: #{e.message}")
        nil
      end

      private

      # Downloads over time, per format, where Redis has the time series module.
      # The total above does not depend on it.
      def series(redis, format)
        redis.call('TS.ADD', "#{DOWNLOADS_KEY}:#{format}", '*', 1,
                   'ON_DUPLICATE', 'SUM', 'LABELS', 'metric', DOWNLOADS_KEY, 'format', format)
      rescue Redis::CommandError => e
        Rails.logger.debug { "box counter: no time series: #{e.message}" }
      end
    end
  end
end
