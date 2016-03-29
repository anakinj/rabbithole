#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require 'bunny'
require 'json'

conn = Bunny.new
conn.start
channel  = conn.create_channel
exchange = channel.topic('my.context', :durable => true)

loop do
  thing = { value: rand(0..10000) }
  puts "\n[PRODUCER] Creating #{thing.inspect} to process"
  exchange.publish(thing.to_json, :routing_key => 'created', :durable => true)
  puts '[PRODUCER] Sleeping for a while'
  sleep rand(3..7)
end
