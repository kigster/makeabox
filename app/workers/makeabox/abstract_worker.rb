require 'sidekiq'

module Makeabox
  module AbstractWorker
    class << self
      def included(base)
        base.instance_eval do
          include Sidekiq::Worker
          sidekiq_options queue: 'default'
        end
      end
    end
  end
end


