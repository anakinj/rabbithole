#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require 'bunny'

require_relative 'consumers'

class ErrorHandlerConsumer < Consumers::EventConsumer
  def initialize
    super('error_handler', 'error.#')
  end

  def perform(delivery_info, metadata, payload)
    puts "[ERROR_HANDLER] ERROR: #{payload.inspect}"
  end
end

class ErrorNotifierConsumer < Consumers::EventConsumer
  def initialize
    super('error_notifier', 'error.*')
  end

  def perform(delivery_info, metadata, payload)
    puts "[ERROR_NOTIFIER] ERROR: #{payload.inspect}"
  end
end

Daemons.run_proc('error_handler', backtrace: true, dir: '.', log_output: true) do
  ErrorHandlerConsumer.new.listen
  ErrorNotifierConsumer.new.listen
  loop do
    sleep(10)
  end
end
