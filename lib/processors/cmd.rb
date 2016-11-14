#!/usr/bin/env ruby
# encoding: utf-8

require_relative 'processor'
require 'syslog/logger'

class Cmd < Processor

  def initialize
    @logger = Syslog::Logger.new 'CsEventtrigger'

    @cmd_create = ENV['cmd_create']
    @cmd_destroy = ENV['cmd_destroy']
  end

  def on_create(id, projectid, jobresult)
    unless @cmd_create.nil?
      cmd = "#{@cmd_create} #{id} #{projectid} #{jobresult}"
      result = %x[ #{cmd} ]
      @logger.info "CMD: #{result}"
    end
  end

  def on_destroy(id, jobresult)
    unless @cmd_destroy.nil?
      cmd = "#{@cmd_destroy} #{id} #{jobresult}"
      @logger.info "CMD: #{cmd}"
      result = %x[ #{cmd} ]
      @logger.info "CMD: #{result}"
    end
  end

end