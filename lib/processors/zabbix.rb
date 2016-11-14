#!/usr/bin/env ruby
# encoding: utf-8

require_relative 'processor'
require 'zabbixapi'
require 'syslog/logger'

class Zabbix < Processor

  def initialize
    @logger = Syslog::Logger.new 'CsEventtrigger'

    @additional_info = ENV['info']

    @zbx = nil
    begin
      @zbx = ZabbixApi.connect(
          :url => ENV['zabbix_url'],
          :user => ENV['zabbix_login'],
          :password => ENV['zabbix_pass']
      )
    rescue => e
      @logger.error e.message
    end
  end

  def query(method, params)
    unless @zbx.nil?
      query = {:method => "#{method}",
               :params => params}
      @zbx.query(query)
    end
  end

  def on_create(id, projectid, jobresult)
    params = {}
    method = ''
    query(method, params)
  end

  def on_destroy(id, jobresult)
    params = {}
    method = ''
    query(method, params)
  end

end