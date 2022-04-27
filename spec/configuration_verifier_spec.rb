require 'configuration_verifier'

RSpec.describe ConfigurationVerifier do
  before(:each) do
    @dir = Dir.pwd
  end

  after(:each) do
    Dir.chdir(@dir)
  end

  describe 'verify' do
    it 'continue if publish directory exists' do
      expect { ConfigurationVerifier.verify_publish_directory('./spec') }.not_to raise_error(SystemExit)
    end
    it 'exit if publish directory is missing' do
      expect { ConfigurationVerifier.verify_publish_directory('./not-existing') }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("Publish directory './not-existing' does not exist in project")
      end
    end
    it 'continue if php is used in commands with enabled php' do
      Dir.chdir('./spec/configTest/phpCommands')
      expect { ConfigurationVerifier.verify_php_commands(php_enabled: true, config: ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)) }.not_to raise_error(SystemExit)
    end
    it 'exit if php is used in pre commands with disabled php' do
      Dir.chdir('./spec/configTest/phpPreCommand')
      expect { ConfigurationVerifier.verify_php_commands(php_enabled: false, config: ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)) }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("Php commands defined in pre deployment remote commands although php is disabled")
      end
    end
    it 'exit if php is used in post commands with disabled php' do
      Dir.chdir('./spec/configTest/phpPostCommand')
      expect { ConfigurationVerifier.verify_php_commands(php_enabled: false, config: ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)) }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("Php commands defined in post deployment remote commands although php is disabled")
      end
    end
  end
end