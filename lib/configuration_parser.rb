# frozen_string_literal: true

require 'yaml'

class ConfigurationParser
  class << self
    def parse(options)
      return Configuration.new(options[:dist_folder]) unless File.exist? '.deploy-now/config.yaml'

      config = YAML.safe_load(File.read('.deploy-now/config.yaml'))

      abort 'version must be specified' unless config.include? 'version'

      version = config['version'].to_s
      abort "unknown version: #{version}" unless version == '1.0'

      parse_1_0(config, options[:dist_folder], options[:bootstrap])
    end

    private

    def parse_1_0(config, dist_folder, bootstrap)
      if config.include? 'deploy'
        deploy_config = config['deploy']['force'] || (bootstrap ? 'bootstrap' : 'recurring')

        abort "deploy configuration '#{deploy_config}' is missing" unless config['deploy'].include? deploy_config

        Configuration.new(dist_folder,
                          config['deploy'][deploy_config]['excludes'] || [],
                          config['deploy'][deploy_config]['remote-commands'])
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
end
