# frozen_string_literal: true

require 'colorize'

class ConfigurationVerifier
  def self.verify_publish_directory(publish_directory)
    abort "Publish directory '#{publish_directory}' does not exist in project".colorize(:red) unless File.directory?(publish_directory)
  end

  def self.verify_php_commands(options)
    php_enabled = options[:php_enabled]
    pre_deployment_remote_commands = options[:config].pre_deployment_remote_commands
    post_deployment_remote_commands = options[:config].post_deployment_remote_commands
    unless php_enabled
      abort "Php commands defined in pre deployment remote commands although php is disabled".colorize(:red) if check_commands(pre_deployment_remote_commands)
      abort "Php commands defined in post deployment remote commands although php is disabled".colorize(:red) if check_commands(post_deployment_remote_commands)
    end
  end

  private

  def self.check_commands(commands)
    !commands.nil? && commands.any? { |c| c.start_with? "php " }
  end

end

