# frozen_string_literal: true

require 'yaml'
require 'colorize'

class ConfigurationParser
  class << self
    def parse(options)
      return Configuration.new(options[:deployment_folder]) unless File.exist? '.deploy-now/config.yaml'

      begin
        config = YAML.safe_load(File.read('.deploy-now/config.yaml'))
      rescue Exception => e
        abort "unable to pare the .deploy-now/config.yaml config file\n#{e}".colorize(:red)
      end

      abort 'version must be specified in .deploy-now/config.yaml config file'.colorize(:red) unless config.include? 'version'

      version = config['version'].to_s
      abort "unknown version: #{version}".colorize(:red) unless version == '1.0'

      parse_1_0(config, options[:deployment_folder], options[:bootstrap])
    end

    private

    def parse_1_0(config, deployment_folder, bootstrap)
      cron_jobs = config.include?('runtime') ? config['runtime']['cron-jobs'] : []
      validate_cron_jobs(cron_jobs)

      if config.include? 'deploy'
        abort "only 'bootstrap' or 'recurring' are allowed for deploy.force in .deploy-now/config.yaml".colorize(:red) unless config['deploy']['force'].eql?('bootstrap') || config['deploy']['force'].eql?('recurring') || config['deploy']['force'].nil?
        deploy_config = config['deploy']['force'] || (bootstrap ? 'bootstrap' : 'recurring')

        if config['deploy'].include? deploy_config
          Configuration.new(deployment_folder,
                            config['deploy'][deploy_config]['excludes'] || [],
                            config['deploy'][deploy_config]['pre-deployment-remote-commands'],
                            config['deploy'][deploy_config]['post-deployment-remote-commands'],
                            cron_jobs)
        else
          Configuration.new(deployment_folder,
                            [],
                            nil,
                            nil,
                            cron_jobs)
        end
      else
        Configuration.new(deployment_folder,
                          [],
                          nil,
                          nil,
                          cron_jobs)
      end
    end

    def validate_cron_jobs(jobs)
      abort 'cron-jobs must be a list'.colorize(:red) unless jobs.is_a? Array
      jobs.each do |job|
        abort "A cron job requires the fields 'command' and 'schedule' in .deploy-now/config.yaml".colorize(:red) unless job.include?('command') && job.include?('schedule')
      end
    end
  end
end

class Configuration
  attr_accessor :deployment_folder, :excludes, :pre_deployment_remote_commands, :post_deployment_remote_commands, :cron_jobs

  def initialize(deployment_folder, excludes = [], pre_deployment_remote_commands = nil, post_deployment_remote_commands = nil, cron_jobs = [])
    @deployment_folder = deployment_folder
    @excludes = excludes
    @pre_deployment_remote_commands = pre_deployment_remote_commands
    @post_deployment_remote_commands = post_deployment_remote_commands
    @cron_jobs = cron_jobs
  end

  def eql(other)
    self.deployment_folder == other.deployment_folder &&
      self.excludes == other.excludes &&
      self.pre_deployment_remote_commands == other.pre_deployment_remote_commands &&
      self.post_deployment_remote_commands == other.post_deployment_remote_commands
      self.cron_jobs == other.cron_jobs
  end

  def to_s
    """{
  deployment_folder: #{self.deployment_folder},
  excludes: #{self.excludes.to_s},
  pre_deployment_remote_commands: #{self.pre_deployment_remote_commands.to_s},
  post_deployment_remote_commands: #{self.post_deployment_remote_commands.to_s},
  cron_jobs: #{self.cron_jobs.to_s}
}"""
  end
end
