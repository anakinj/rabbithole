#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require 'json'

require_relative 'consumers'

puts '[TRANSITION_GENERATE] Starting...'

class ContextGenerateTransition < Consumers::TransitionConsumer
  def initialize
    super('generate')
  end

  def perform(delivery_info, metadata, payload)
    puts "[TRANSITION_GENERATE] Got a new task: #{payload.inspect}"

    obj = JSON.parse(payload)

    if obj['value'] > 2000
      puts "[TRANSITION_GENERATE] Cannot handle values bigger than 2000"
      raise StandardError, 'Cannot handle'
    else
      puts "[TRANSITION_GENERATE] Generating"
      sleep(rand(1..5))
      puts "[TRANSITION_GENERATE] Generation ready"
      publish_ready(payload)
    end
  rescue StandardError
    publish_error(payload)
  end
end

Daemons.run_proc('transition_generate', backtrace: true, dir: '.', log_output: true) do
  ContextGenerateTransition.new.listen

  loop do
    sleep(10)
  end
end
