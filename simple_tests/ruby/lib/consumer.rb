require 'bunny'

def logger
  @logger ||= Logger.new(STDOUT)
end

bunny = Bunny.new(vhost: '/playground')

logger.info('Opening TCP connection to RabbitMQ intance')
bunny.start

logger.info('Connection established, creating channel')
channel = bunny.create_channel

logger.info('Creating/Getting handle for exchanges')

exchange = channel.topic('my.little.pony.topic')
dlx      = channel.topic('my.little.dead-pony.topic')

logger.info('Creating/Getting handle for queues')
red        = channel.queue("my.consumer.red", 
                           arguments: {"x-dead-letter-exchange" => dlx.name})

all_colors = channel.queue("my.consumer.all-colors",
                           arguments: {"x-dead-letter-exchange" => dlx.name})

black      = channel.queue("my.consumer.black", 
                           arguments: {"x-dead-letter-exchange" => dlx.name})

dead       = channel.queue("my.consumer.dead")

nack       = channel.queue("my.consumer.negative-ack",
                           arguments: {"x-dead-letter-exchange" => dlx.name})

logger.info('Binding queues to exchange')

black.bind(exchange, :routing_key => 'color.black')
black.bind(exchange, :routing_key => 'all')

red.bind(exchange, :routing_key => 'color.red')
red.bind(exchange, :routing_key => 'all')

all_colors.bind(exchange, :routing_key => 'color.*')
all_colors.bind(exchange, :routing_key => 'all')

nack.bind(exchange, :routing_key => 'nack')
nack.bind(exchange, :routing_key => 'all')

dead.bind(dlx)

logger.info('Subscribing to queue messages')

def handler(name, routing_key, payload)
  logger.info "#{name} | '#{payload}'"
end

black.subscribe do |delivery_info, properties, payload|
  handler('BLACK', delivery_info.routing_key, payload)
end

red.subscribe do |delivery_info, properties, payload|
  handler('RED', delivery_info.routing_key, payload)
end

all_colors.subscribe do |delivery_info, properties, payload|
  handler('ALL-COLOR', delivery_info.routing_key, payload)
end

nack.subscribe(manual_ack: true) do |delivery_info, properties, payload|
  handler('NACK', delivery_info.routing_key, payload)
  delivery_info.channel.reject(delivery_info.delivery_tag)
end

dead.subscribe do |delivery_info, properties, payload|
  handler('DEADHANDLER', delivery_info.routing_key, payload)
end

begin
  while true do
    sleep 0.1
  end
rescue Interrupt => _
  channel.close
  connection.close
end

