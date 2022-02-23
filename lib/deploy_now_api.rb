# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'passgen'

class DeployNowApi
  def initialize(options)
    @client = RestClient::Resource.new("https://#{options[:endpoint]}",
                                       headers: { authorization: "API-Key #{options[:api_key]}" })
    @project_id = options[:project_id]
    @branch_id = options[:branch_id]
  end

  def create_temporary_user
    password = Passgen.generate(length: 30, symbols: true)
    retry_counter = 3
    response = nil
    loop do
      retry_counter -= 1
      begin
        response = @client["/v1/projects/#{@project_id}/branches/#{@branch_id}/users"].post({ password: password }.to_json,
                                                                                            content_type: 'application/json')
        break
      rescue RestClient::Exception
        abort 'Failed to create temporary user' if retry_counter.zero?
      end

      puts 'Retry creating temporary user in 1 second'
      sleep 1
    end

    abort 'Failed to create temporary user' unless response.code == 200

    username = JSON.parse(response.body)['username']
    puts "Created temporary user: #{username}"

    { username: username, password: password }
  end

  def update_deployment_status
    @client["/v1/projects/#{@project_id}/branches/#{@branch_id}/hooks/DEPLOYED"].put(nil,
                                                                                     content_type: 'application/json')
  end

  def get_web_space_info
    response = @client["/v1/projects/#{@project_id}/branches/#{@branch_id}"].get
    JSON.parse(response.body)['webSpace']
  end
end
