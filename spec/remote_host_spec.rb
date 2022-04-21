require "remote_host"
require 'net/ssh/connection/session'

RSpec.describe RemoteHost do
  describe 'deploy' do
    it 'should run the right rsync command' do
      user = { username: "a1234", password: "password" }
      host = "localhost"
      exclude = %w[logs .deploy-now .git .github css/dummy.css]
      dist = './'
      cmd = "rsync -avE --delete --rsh=\"/usr/bin/sshpass -e ssh -o StrictHostKeyChecking=no\" --exclude=logs --exclude=.deploy-now --exclude=.git --exclude=.github --exclude=css/dummy.css ./ a1234@localhost:"

      io = double(IO)

      allow(IO).to receive(:popen).with(ENV.merge!({ 'SSHPASS' => user[:password] }), cmd).and_yield(io)
      allow(io).to receive(:each).and_yield("rsync response")

      remote_host = RemoteHost.new(user: user, host: host)
      remote_host.deploy(dist_folder: dist,
                         excludes: exclude)

    end
  end
end

