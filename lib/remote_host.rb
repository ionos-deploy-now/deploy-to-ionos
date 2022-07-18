# frozen_string_literal: true

require 'English'
require 'net/ssh'

class RemoteHost
  def initialize(options)
    @user = options[:user]
    @host = options[:host]
  end

  def deploy(options)
    exclude_options = (options[:excludes]).map { |exclude| "--exclude=#{exclude}" }.join(' ')
    dist_folder = options[:dist_folder]
    dist_folder += '/' unless dist_folder.end_with? '/'
    cmd = "rsync -avE --delete --rsh=\"/usr/bin/ssh -o StrictHostKeyChecking=no\" #{exclude_options} #{dist_folder} #{@user[:username]}@#{@host}:"
    puts cmd
    IO.popen(cmd) do |io|
      io.each do |line|
        puts line
      end
    end

    exit $CHILD_STATUS.exitstatus unless $CHILD_STATUS.exitstatus.zero?
  end

  def execute(commands)
    Net::SSH.start(@host, @user[:username], verify_host_key: :never) do |ssh|
      commands.each do |command|
        puts "Running the remote command: #{command}"
        status = {}
        ssh.exec!(command, status: status) do |_, _, data|
          puts data
        end
        abort 'Error running the remote command'.colorize(:red) unless status[:exit_code].zero?
      end
    end
  end
end
