# frozen_string_literal: true

require 'yaml'

class ConfigurationParser
  class << self
    def parse(options)
      return Configuration.new(options[:dist_folder]) unless File.exist? '.deploy-now/config.yaml'

      begin
        config = YAML.safe_load(File.read('.deploy-now/config.yaml'))
      rescue Exception => e
        abort "unable to pare the .deploy-now/config.yaml config file\n#{e}"
      end

      abort 'version must be specified in .deploy-now/config.yaml config file' unless config.include? 'version'

      version = config['version'].to_s
      abort "unknown version: #{version}" unless version == '1.0'

      parse_1_0(config, options[:dist_folder], options[:bootstrap])
    end

    private

    def parse_1_0(config, dist_folder, bootstrap)
      if config.include? 'deploy'
        abort "only 'bootstrap' or 'recurring are allowed for deploy.force in .deploy-now/config.yaml" unless config['deploy']['force'].eql?('bootstrap') || config['deploy']['force'].eql?('recurring') || config['deploy']['force'].nil?
        deploy_config = config['deploy']['force'] || (bootstrap ? 'bootstrap' : 'recurring')

        if config['deploy'].include? deploy_config
          Configuration.new(dist_folder,
                            config['deploy'][deploy_config]['excludes'] || [],
                            config['deploy'][deploy_config]['remote-commands'])
        else
          Configuration.new(dist_folder,
                            [],
                            nil)
        end
      else
        Configuration.new(dist_folder)
      end
    end
  end
end

class Configuration
  attr_accessor :dist_folder, :excludes, :remote_commands

  def initialize(dist_folder, excludes = [], remote_commands = nil)
    @dist_folder = dist_folder
    @excludes = excludes
    @remote_commands = remote_commands
  end

  def eql(other)
    self.dist_folder == other.dist_folder &&
      self.excludes == other.excludes &&
      self.remote_commands == other.remote_commands
  end

  def to_s
    "{dist: \"#{self.dist_folder}\", excludes: #{self .excludes.to_s}, remote_commands:#{self.remote_commands.to_s}}"
  end
end
