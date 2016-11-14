#!/usr/bin/env ruby
# encoding: utf-8

require 'bunny'
require 'json'
require 'syslog/logger'
require 'daemons'
require 'optparse'

load 'lib/event_processor.rb'

class CsEventtrigger

  def initialize
    @logger = Syslog::Logger.new 'CsEventtrigger'

    @logger.info 'Starting CsEventtrigger'

    @queue_name = ENV['rabbitmq_queue']
    begin
      @conn = Bunny.new(
          :host => ENV['rabbitmq_host'],
          :port => ENV['rabbitmq_port'].to_i,
          :user => ENV['rabbitmq_user'],
          :password => ENV['rabbitmq_pass'])
      @conn.start
      @channel = @conn.create_channel
      @event_processor = EventProcessor.new
    rescue => e
      @logger.error e.message
      exit 1
    end
  end

  def finalize
    @channel.close
    @conn.close
  end

  def logger
    @logger
  end

  def on_create(json_body, cmdinfo_json)
    id = json_body['instanceUuid']
    projectid = cmdinfo_json['projectid']
    jobresult = json_body['jobResult']
    jobresult.slice! 'org.apache.cloudstack.api.response.UserVmResponse/virtualmachine/'
    @event_processor.on_create(id, projectid, jobresult)
  end

  def on_destroy(cmdinfo_json)
    id = cmdinfo_json['id']
    projectid = cmdinfo_json['projectid']
    @event_processor.on_destroy(id, projectid)
  end

  def capture

    begin

      if @conn.queue_exists?(@queue_name)

        queue = @channel.queue(@queue_name, :no_declare => true)
        asyncjob_prefix = 'management-server.AsyncJobEvent'
        key_complete = "#{asyncjob_prefix}.complete.VirtualMachine"
        key_submit = "#{asyncjob_prefix}.submit.VirtualMachine"

        begin
          queue.subscribe(:block => true) do |delivery_info, properties, body|
            key_prefix = delivery_info.routing_key.split('.').take(4).join('.')
            if key_prefix.eql? key_complete or key_prefix.eql? key_submit
              json_body = JSON body
              cmdinfo_json = JSON json_body['cmdInfo']
              if cmdinfo_json['cmdEventType'].eql? 'VM.CREATE' and json_body['status'].eql? 'SUCCEEDED'
                  on_create(json_body, cmdinfo_json)
              elsif cmdinfo_json['cmdEventType'].eql? 'VM.DESTROY' and json_body['status'].eql? 'IN_PROGRESS'
                  on_destroy(cmdinfo_json)
              end
            end
          end
        rescue Interrupt => _
          finalize
        end

      else
        @logger.error "Queue #{@queue_name} not exit"
      end

    rescue => e
      @logger.error e.message
    end

  end

end

if __FILE__ == $0
  options = { :daemonize => false }
  parser = OptionParser.new do|opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on('-d', '--daemon', 'Deamonize') do
      options[:daemonize] = true;
    end
    opts.on('-h', '--help', 'Displays Help') do
      puts opts
      exit
    end
  end
  parser.parse!

  Daemons.daemonize({:app_name => 'cs_eventtrigger', :backtrace  => true}) if options[:daemonize]
  cs = CsEventtrigger.new
  cs.capture
end
