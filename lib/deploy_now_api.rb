# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'ld-eventsource'

class DeployNowApi
  def initialize(options)
    @client = RestClient::Resource.new("https://#{options[:endpoint]}",
                                       headers: { authorization: "API-Key #{options[:api_key]}" })
    @endpoint = options[:endpoint]
    @api_key = options[:api_key]
    @project_id = options[:project_id]
    @branch_id = options[:branch_id]
  end

  def create_temporary_user(password)
    begin
      response = @client["/v2/projects/#{@project_id}/branches/#{@branch_id}/users"].post({ password: password }.to_json,
                                                                                          content_type: 'application/json')
      abort 'Failed to create temporary user' unless response.code == 200
      JSON.parse(response.body)['id']
    rescue RestClient::Exception
      abort 'Failed to create temporary user'
    end
  end

  def create_database_user(password)
    begin
      response = @client["/v2/projects/#{@project_id}/branches/#{@branch_id}/database/users"].post({ password: password }.to_json,
                                                                                                   content_type: 'application/json')
      abort 'Failed to create temporary user' unless response.code == 200
      JSON.parse(response.body)['id']
    rescue RestClient::Exception
      abort 'Failed to create temporary user'
    end
  end

  def update_deployment_status
    @client["/v2/projects/#{@project_id}/branches/#{@branch_id}/hooks/DEPLOYED"].put(nil,
                                                                                     content_type: 'application/json')
  end

  def get_branch_info
    response = @client["/v2/projects/#{@project_id}"].get
    project = JSON.parse(response.body)
    is_production_branch = project['productionBranch']['id'] == @branch_id
    branch = is_production_branch ? project['productionBranch'] : project['branches'].select { |b| b['id'] == @branch_id }.first
    {
      app_url: is_production_branch ? "https://#{project['domain']}" : branch['webSpace']['siteUrl'],
      last_deployment_date: branch['webSpace']['lastDeploymentDate'],
      database: branch.include?('database') ? { host: branch['database']['host'], name: branch['database']['name'] } : nil,
      storage_quota: branch['webSpaceQuota']['storageQuota'].to_i,
      ssh_host: branch['webSpace']['sshHost'],
      php_version: branch['webSpace']['phpVersion']
    }.compact
  end

  def get_user_events(&block)
    SSE::Client.new("https://#{@endpoint}/v2/projects/#{@project_id}/branches/#{@branch_id}/events",
                    headers: { authorization: "API-Key #{@api_key}" }) do |client|
      client.on_event(&block)
    end
  end
end
