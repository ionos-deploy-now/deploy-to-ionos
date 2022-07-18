# frozen_string_literal: true

require 'rest-client'
require 'json'
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

  def update_deployment_status
    @client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/deployed"].post(nil,
                                                                                            content_type: 'application/json')
  end

  def get_branch_info
    response = @client["/v3/accounts/me/projects/#{@project_id}"].get
    project = JSON.parse(response.body)
    is_production_branch = project['productionBranch']['id'] == @branch_id
    branch = JSON.parse(@client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}"].get.body)
    {
      app_url: is_production_branch ? "https://#{project['domain']}" : branch['webSpace']['webSpace']['siteUrl'],
      last_deployment_date: branch['lastDeploymentDate'],
      database: branch.include?('database') ? { id: branch['database']['database']['id'],
                                                host: branch['database']['database']['host'],
                                                name: branch['database']['database']['name'] } : nil,
      storage_quota: branch['webSpace']['webSpace']['quota']['storageQuota'].to_i,
      ssh_host: branch['webSpace']['webSpace']['sshHost'],
      php_version: branch['webSpace']['webSpace']['phpVersion'],
      web_space_id: branch['webSpace']['webSpace']['id']
    }.compact
  end

  def configure_cron_jobs(jobs)
    @client["/v3/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/cron-jobs"].put(jobs.to_json,
                                                                                            content_type: 'application/json')
  end
end
