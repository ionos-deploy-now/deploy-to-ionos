# frozen_string_literal: true

require 'rest-client'
require 'json'

class DeployNowApi
  def initialize(options)
    @client = RestClient::Resource.new("https://#{options[:endpoint]}",
                                       headers: { authorization: "API-Key #{options[:api_key]}" })
    @endpoint = options[:endpoint]
    @api_key = options[:api_key]
    @project_id = options[:project_id]
    @branch_id = options[:branch_id]
    @deployment_id = options[:deployment_id]
    @webspace_id = options[:webspace_id]
  end

  def configure_cron_jobs(jobs)
    @client["/v4/accounts/me/projects/#{@project_id}/branches/#{@branch_id}/deployments/#{@deployment_id}/webspaces/#{@webspace_id}/cron-jobs"].put(jobs.to_json,
                                                                                                                                                    content_type: 'application/json')
  end
end
