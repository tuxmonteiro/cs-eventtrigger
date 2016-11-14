#!/usr/bin/env ruby
# encoding: utf-8

require_relative 'processor'
require 'syslog/logger'
require 'rest-client'

class Foreman < Processor

  def initialize
    @logger = Syslog::Logger.new 'CsEventtrigger'

    @additional_info = ENV['info']

    @foreman_api = ENV['foreman_api']
    @foreman_user = ENV['foreman_user']
    @foreman_pass = ENV['foreman_pass']
  end

  def exist(host)
    resource = RestClient::Resource.new("#{@foreman_api}/hosts/#{host}", :user => @foreman_user, :password => @foreman_pass)
    begin
      response = resource.get
      return response.code == 200
    rescue RestClient::ResourceNotFound
      return false
    rescue RestClient::Unauthorized
      @logger.error 'Foreman: [FAIL] RestClient::Unauthorized'
      return false
    end
  end

  def fix(host)
    real_env = @additional_info['environment_id']
    hostgroup = @additional_info['hostgroup_id']
    data = {
        :host => {
            :environment_id => "#{real_env}",
            :hostgroup_id => "#{hostgroup}"
        }
    }
    resource = RestClient::Resource.new("#{@foreman_api}/v2/hosts/#{host}", :user => @foreman_user, :password => @foreman_pass)
    resource.put(data.to_json, :content_type => 'application/json') { |response, request, result|
      @logger.info "Foreman: #{response}"
    }
  end

  def on_create(id, projectid, jobresult)
    # fix env
    name = jobresult['name']
    unless name.nil?
      fix(name) if exist(name)
    end
  end

  def on_destroy(id, jobresult)
    #
  end

end