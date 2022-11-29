# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'ld-eventsource'
require 'colorize'

class DeployNowApi
  def initialize(options)
    @client = RestClient::Resource.new("https://#{options[:endpoint]}",
                                       headers: { authorization: "API-Key #{options[:api_key]}" })
    @endpoint = options[:endpoint]
    @api_key = options[:api_key]
    @project_id = options[:project_id]
    @branch_id = options[:branch_id]
  end

  def create_temporary_user(space_id, password)
    begin
      response = @client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/spaces/#{space_id}/users"].post({ password: password,
                                                                                                                           expiration: "PT5M" }.to_json,
                                                                                                                         content_type: 'application/json')
      abort 'Failed to create temporary user'.colorize(:red) unless response.code == 202
      JSON.parse(response.body)['id']
    rescue RestClient::Exception
      abort 'Failed to create temporary user'.colorize(:red)
    end
  end

  def create_database_user(database_id, password)
    begin
      response = @client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/databases/#{database_id}/users"].post({ password: password }.to_json,
                                                                                                                               content_type: 'application/json')
      abort 'Failed to create database user'.colorize(:red) unless response.code == 202
      JSON.parse(response.body)['id']
    rescue RestClient::Exception
      abort 'Failed to create database user'.colorize(:red)
    end
  end

  def update_deployment_status
    @client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/deployed"].post(nil,
                                                                                            content_type: 'application/json')
  end

  def get_branch_info
    deployments = JSON.parse(@client["/v4/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/deployments"].get.body)
    abort "v1 of this action doesn't support multi deployments".colorize(:red) if deployments['total'] > 1
    deployment = JSON.parse(@client["/v4/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/deployments/#{deployments['values'].first['id']}"].get.body)
    {
      app_url: "https://#{deployment['domain']['name']}",
      last_deployment_date: deployment['state']['lastDeployedDate'],
      database: deployment.include?('database') ? { id: deployment['database']['database']['id'],
                                                host: deployment['database']['database']['host'],
                                                name: deployment['database']['database']['name'] } : nil,
      storage_quota: deployment['webspace']['webspace']['quota']['storageQuota'].to_i,
      ssh_host: deployment['webspace']['webspace']['sshHost'],
      php_version: deployment['webspace']['webspace']['phpVersion'],
      web_space_id: deployment['webspace']['webspace']['id']
    }.compact
  end

  def get_user_events(&block)
    SSE::Client.new("https://#{@endpoint}/v3/accounts/me/github-action-events?projectId=#{@project_id}&branchId=#{@branch_id}",
                    headers: { authorization: "API-Key #{@api_key}" }) do |client|
      client.on_event(&block)
    end
  end

  def configure_cron_jobs(jobs)
    @client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/cron-jobs"].put(jobs.to_json,
                                                                                            content_type: 'application/json')
  end
end
