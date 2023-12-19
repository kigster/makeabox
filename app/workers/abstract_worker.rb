# frozen_string_literal: true

class AbstractWorker
  class << self
    def inherited(base)
      super(base)
      base.include(Sidekiq::Worker)
      base.include(Makeabox::WithLogging)
      base.include(Makeabox::PDF::RedisConcern)
    end
  end
end
