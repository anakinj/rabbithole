require 'bunny'

module Consumers
  module Queue
    def self.included(base)
      base.instance_variable_set(:@queue_name, nil)
      base.extend ClassMethods
    end

    module ClassMethods
      def queue(name)
        @queue_name = name
      end

      def listen

      end
    end
  end

  module BunnyConsumer
    def self.included(base)
      base.instance_variable_set(:@queue_name, nil)
      base.extend ClassMethods
    end

    module ClassMethods
      def init
        @connection = Bunny.new
        @connection.start
        @channel  = @connection.create_channel
        @queue    = create_queue_handle(@queue_name)
      end
    end
  end
end
