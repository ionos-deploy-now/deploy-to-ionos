require "size_checker"

RSpec.describe SizeChecker do
  describe 'check' do
    it 'aborts if size exceeds allowed_size' do
      user = { username: "a1234", password: "password" }
      host = "localhost"
      exclude = %w[logs .deploy-now .git .github css/dummy.css]
      sshCommand = 'expr $(du -sb . | cut -f1 ) - $(du -sb . --exclude=logs --exclude=.deploy-now --exclude=.git --exclude=.github --exclude=css/dummy.css | cut -f1)'

      @ssh = double(Net::SSH)
      allow(Net::SSH).to receive(:start).with(host, user[:username], password: user[:password], verify_host_key: :never).and_yield(@ssh)
      allow(@ssh).to receive(:exec!).with(sshCommand).and_return("1063923")

      expect { SizeChecker.check(dist_folder: './spec/remoteFolder',
                                 excludes: exclude,
                                 user: user,
                                 host: host,
                                 allowed_size: 50) }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("The deployment is larger (1065043) than the allowed quota (50)".colorize(:red))
      end
    end

    it 'returns nil if size smaller than allowed size_size' do
      user = { username: "a1234", password: "password" }
      host = "localhost"
      exclude = %w[logs .deploy-now .git .github css/dummy.css]
      sshCommand = 'expr $(du -sb . | cut -f1 ) - $(du -sb . --exclude=logs --exclude=.deploy-now --exclude=.git --exclude=.github --exclude=css/dummy.css | cut -f1)'

      @ssh = double(Net::SSH)
      allow(Net::SSH).to receive(:start).with(host, user[:username], password: user[:password], verify_host_key: :never).and_yield(@ssh)
      allow(@ssh).to receive(:exec!).with(sshCommand).and_return("1063923")

      expect(SizeChecker.check(dist_folder: './spec/remoteFolder',
                               excludes: exclude,
                               user: user,
                               host: host,
                               allowed_size: 50003968))
        .to be_nil
    end
  end
end
