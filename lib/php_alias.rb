# frozen_string_literal: true

class PhpAlias
  DEPLOY_NOW_FOLDER = '.deploy-now/'

  def initialize(options)
    @disabled = options[:php_version].nil?
    php_version = options[:php_version]
    @symlink_target = "/usr/bin/php#{php_version}-cli"
    @symlink_file = "#{DEPLOY_NOW_FOLDER}php"
    @bash_path = "PATH=~/#{DEPLOY_NOW_FOLDER}:$PATH"
  end

  attr_reader :disabled

  def create_alias_commands
    [
      "mkdir -p ~/#{DEPLOY_NOW_FOLDER}",
      "ln -sf #{@symlink_target} ~/#{@symlink_file}"
    ]
  end

  def activate_alias_commands
    [
      "grep -qsxF '#{@bash_path}' ~/.bash_profile || echo '#{@bash_path}' >> ~/.bash_profile",
      "grep -qsxF '#{@bash_path}' ~/.bashrc || echo '#{@bash_path}' >> ~/.bashrc"
    ]
  end
end
