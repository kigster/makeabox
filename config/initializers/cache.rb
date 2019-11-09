require 'forwardable'
class Cache
  class << self

    extend Forwardable

    def client
      @cache ||= ConnectionPool.new(size: 10, timeout: 3) { Dalli::Client.new }
    end

    def dalli
      client.with do |dalli_client|
        yield(dalli_client)
      end
    end
  end
end

Cache.client { |d| pp d.stats }
