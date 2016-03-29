require 'bunny'

module Consumers
  class ContextConsumer
    TOPIC = 'my.context'.freeze

    def initialize(queue_name)
      @queue_name = queue_name
      @connection = Bunny.new
      start
    end

    def start
      @connection.start
      @channel  = @connection.create_channel
      @exchange = @channel.topic(TOPIC, durable: true)
      @queue    = create_queue_handle(@queue_name)
    end

    def listen
      @queue.subscribe(manual_ack: true) do |delivery_info, metadata, payload|
        begin
          if perform(delivery_info, metadata, payload)
            ack(delivery_info)
          else
            nack(delivery_info)
          end
        rescue
          nack(delivery_info)
        end
      end
    end

    def perform(delivery_info, metadata, payload)
      raise NotImplementedError, 'You need to implement this'
    end

    def ack(delivery_info)
      @channel.ack(delivery_info.delivery_tag)
    end

    def nack(delivery_info)
      @channel.nack(delivery_info.delivery_tag)
    end

    def publish_error(payload)
      publish(payload, "error.#{queue_name}")
    end

    def publish_ready(payload)
      publish(payload, "ready.#{queue_name}")
    end

    def publish(payload, routing_key)
      @exchange.publish(payload, routing_key: routing_key)
    end

    def create_queue_handle(queue_name)
      @channel.queue("#{TOPIC}.#{queue_name}", durable: true)
    end
  end

  class TransitionConsumer < ContextConsumer
    def initialize(name)
      super("transition.#{name}")
    end
  end

  class EventConsumer < ContextConsumer
    def initialize(name, routing_key)
      @routing_key = routing_key
      super("#{name}")
    end

    def start
      super
      @queue.bind(@exchange, :routing_key => @routing_key)
    end
  end
end
