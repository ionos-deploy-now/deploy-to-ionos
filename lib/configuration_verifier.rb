# frozen_string_literal: true

require 'colorize'

class ConfigurationVerifier
  def self.verify(options)
    php_enabled = options[:php_enabled]
    config = options[:config]

    abort "Publish directory '#{config.deployment_folder}' does not exist in project".colorize(:red) unless exists_directory(config.deployment_folder)
    unless php_enabled
      abort 'Php commands defined in pre deployment remote commands although php is disabled'.colorize(:red) if check_commands(config.pre_deployment_remote_commands)
      abort 'Php commands defined in post deployment remote commands although php is disabled'.colorize(:red) if check_commands(config.post_deployment_remote_commands)
    end
    abort 'Cron jobs are only allowed for PHP projects'.colorize(:red) unless php_enabled or config.cron_jobs.empty?
  end

  private

  def self.check_commands(commands)
    !commands.nil? && commands.any? { |c| c.start_with? "php " }
  end

  def self.exists_directory(directory)
    File.directory?(directory) || (File.symlink?(directory) && File.directory?(File.readlink(directory)))
  end
end

