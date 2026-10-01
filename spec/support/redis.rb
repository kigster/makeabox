# frozen_string_literal: true

# Every example starts with no download count, so the counter is back at its
# starting total. The test environment has a Redis database of its own
# (see config/initializers/redis.rb).
RSpec.configure do |config|
  config.before do
    REDIS.with { |redis| redis.del(Makeabox::BoxCounter::DOWNLOADS_KEY) }
  end
end
