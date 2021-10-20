# frozen_string_literal: true

require 'net/ssh'

class SizeChecker
  class << self
    def check(options)
      deployment_size = calculate_local_size(options[:dist_folder], options[:excludes])
      remote_excludes_size = calculate_remote_excludes_size(options[:user],
                                                            options[:host],
                                                            options[:excludes])

      size = deployment_size + remote_excludes_size

      if size > options[:allowed_size]
        abort "The deployment is larger (#{size}) than the allowed quota (#{options[:allowed_size]})"
      end
    end

    private

    def calculate_local_size(dist_folder, excludes)
      get_entries(dist_folder).reject { |entry| excludes.include? entry }
                              .map { |entry| File.directory?(dist_folder + File::SEPARATOR + entry) ?
                                               calculate_dir_size(dist_folder + File::SEPARATOR + entry) :
                                               File.size(dist_folder + File::SEPARATOR + entry) }
                              .sum
    end

    def calculate_dir_size(dir)
      size = 0
      get_entries(dir).each do |entry|
        path = "#{dir}#{File::SEPARATOR}#{entry}"

        size += if File.directory? path
                  calculate_dir_size(path)
                else
                  File.size(path)
                end
      end
      size
    end

    def get_entries(dir)
      Dir.entries(dir).select { |value| value != '.' && value != '..' }
    end

    def calculate_remote_excludes_size(user, host, excludes)
      return 0 if excludes.empty?

      exclude_options = (excludes).map { |exclude| "--exclude=#{exclude}" }.join(' ')

      Net::SSH.start(host, user[:username], password: user[:password], verify_host_key: :never) do |ssh|
        ssh.exec!("expr $(du -sb . | cut -f1 ) - $(du -sb . #{exclude_options} | cut -f1)").to_i
      end
    end
  end
end
