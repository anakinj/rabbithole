require 'bunny'
require 'io/console'
def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

logger = Logger.new(STDOUT)

bunny = Bunny.new(vhost: '/playground')

logger.info('Opening TCP connection to RabbitMQ intance')
bunny.start

logger.info('Connection established, creating channel')
channel = bunny.create_channel

logger.info('Creating/Getting handle for exchange and queue')
exchange = channel.topic('my.little.pony.topic')

def main(connection, channel, exchange)
  puts 'Following options available: a,b,r,n,d,e'
  begin
    c = read_char
    case c
    when 'd'
      puts 'Publishing to queue by queue name'
      channel.default_exchange.publish("'Directly' to the queue (via the default exchange)", :routing_key => 'my.consumer.black')
    when 'r'
      puts 'Publishing to RED queue'
      exchange.publish("Publish to the RED", routing_key: 'color.red')
    when 'b'
      puts 'Publishing to BLACK queue'
      exchange.publish("Publish to the BLACK", routing_key: 'color.black')
    when 'a'
      puts 'Publishing to all queues'
      exchange.publish("Publish to all", routing_key: 'all')
    when 'n'
      puts 'Publishing to NACK queue'
      exchange.publish("Publish to NACK", routing_key: 'nack')
    when 'e'
      exit
    end
  rescue Interrupt => _
    channel.close
    connection.close
    exit
  end
end

main(bunny, channel, exchange) while(true)


