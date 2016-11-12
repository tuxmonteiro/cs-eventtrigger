#!/usr/bin/env ruby
# encoding: utf-8

require 'bunny'

class CsEventtrigger

  def initialize
    @conn = Bunny.new(
        :host => ENV['rabbitmq_host'],
        :port => ENV['rabbitmq_port'].to_i,
        :user => ENV['rabbitmq_user'],
        :password => ENV['rabbitmq_pass'])
    @conn.start
    @channel = @conn.create_channel
  end

  def finalize
    @channel.close
    @conn.close
  end

  def capture

    if @conn.queue_exists?(ENV['rabbitmq_queue'])

      queue = @channel.queue(ENV['rabbitmq_queue'], :no_declare => true)
      # exchange = @channel.fanout(ENV['rabbitmq_exchange'], :passive => true)
      # queue.bind(exchange, :routing_key => ENV['rabbitmq_routing_key'])

      begin
        queue.subscribe(:block => true) do |delivery_info, properties, body|
          puts " [x] #{delivery_info.routing_key}: #{body}"
        end
      rescue Interrupt => _
        finalize
      end

    else
      fail('queue not exit')
    end

  end

end

cs = CsEventtrigger.new
cs.capture

