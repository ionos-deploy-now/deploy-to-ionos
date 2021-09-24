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
                              .map { |entry| File.directory?(entry) ? calculate_dir_size(entry) : File.size(entry) }
                              .sum
    end

    def calculate_dir_size(dir)
      size = File.size(dir)
      get_entries(dir).each do |entry|
        path = "#{dir}/#{entry}"
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

    def calculate_remote_excludes_size(user, host, dirs)
      return 0 if dirs.empty?

      Net::SSH.start(host, user[:username], password: user[:password], verify_host_key: :never) do |ssh|
        ssh.exec!('shopt -s dotglob; du -sb *')
           .scan(/(\d+)\s+(\S+)/)
           .select { |_, path| dirs.include? path }
           .map { |size, _| size.to_i }
           .sum
      end
    end
  end
end
