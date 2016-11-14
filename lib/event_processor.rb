#!/usr/bin/env ruby
# encoding: utf-8

require 'redis'
require 'json'
require 'syslog/logger'

require_relative 'processors/zabbix'
require_relative 'processors/foreman'
require_relative 'processors/cmd'

class EventProcessor

  def initialize(options = {})
    @logger = Syslog::Logger.new 'CsEventtrigger'
    @processors = []

    # register (Zabbix.new)
    # register (Foreman.new)
    register (Cmd.new)

    begin
      if options['sentinels'].nil?
        @redis = Redis.new(:url => 'redis://127.0.0.1:6379/0')
      else
        @redis = Redis.new(:url => 'redis://mymaster', :sentinels => options['sentinels'], :role => :master)
      end

    rescue => e
      @logger.error e.message
      exit 1
    end
  end

  def register(processor)
    @processors.add(processor)
  end

  def on_create(id, projectid, jobresult)
    @logger.info "CREATE id: #{id}, projectid: #{projectid}"
    jobresult_json = JSON jobresult
    @processors.each do |p|
      p.on_create(id, projectid, jobresult_json)
    end
    # name = jobresult_json['name']
    @redis.set id, {:json => jobresult_json}.to_json
  end

  def on_destroy(id, projectid)
    @logger.info "DESTROY id: #{id}, projectid: #{projectid}"
    jobresult_json = JSON @redis.get id
    @processors.each do |p|
      p.on_destroy(id, jobresult_json)
    end
    # @logger.info "  name: #{jobresult_json['json']['name']}"
    @redis.del id
  end

end