#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require "bunny"
require_relative 'consumers'

puts '[ORCHESTRATOR] Starting..'

class OrchestatorCreatedConsumer < Consumers::EventConsumer
  def initialize
    super('orchestrator.created', 'created')
  end

  def perform(delivery_info, metadata, payload)
    puts "[ORCHESTRATOR] I got a new thing: #{payload.inspect}."
    puts "[ORCHESTRATOR] Will pass it to generate transition.\n\n"

    generate_queue.publish(payload, persistent: true)
  end

  def generate_queue
    @generate_queue ||= create_queue_handle('transition.generate')
  end
end

class OrchestatorErrorConsumer < Consumers::EventConsumer
  def initialize
    super('orchestrator.errors', 'error.#')
  end

  def perform(delivery_info, metadata, payload)
    puts "[ORCHESTRATOR] Received an ERROR: #{payload.inspect}."
    puts "[ORCHESTRATOR] I might be able to handle it, but will not.\n"
  end
end

Daemons.run_proc('orchestrator', backtrace: true, dir: '.', log_output: true) do
  OrchestatorCreatedConsumer.new.listen
  OrchestatorErrorConsumer.new.listen

  loop do
    sleep(10)
  end
end
