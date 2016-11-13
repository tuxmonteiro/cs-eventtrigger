#!/usr/bin/env ruby
# encoding: utf-8

require 'redis'
require 'json'
require 'syslog/logger'

class EventProcessor

  def initialize(options = {})
    @logger = Syslog::Logger.new 'CsEventtrigger'

    if options['sentinels'].nil?
      @redis = Redis.new(:url => 'redis://127.0.0.1:6379/0')
    else
      @redis = Redis.new(:url => 'redis://mymaster', :sentinels => options['sentinels'], :role => :master)
    end
  end

  def on_create(id, projectid, jobresult)
    @logger.info "CREATE id: #{id}, projectid: #{projectid}"
    jobresult_json = JSON jobresult
    # name = jobresult_json['name']
    @redis.set id, {:json => jobresult_json}.to_json
  end

  def on_destroy(id, projectid)
    @logger.info "DESTROY id: #{id}, projectid: #{projectid}"
    # jobresult_json = JSON @redis.get id
    # @logger.info "  name: #{jobresult_json['json']['name']}"
    @redis.del id
  end

end