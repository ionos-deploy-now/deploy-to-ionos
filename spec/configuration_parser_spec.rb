require "configuration_parser"

RSpec.describe ConfigurationParser do
  before(:each) do
    @dir = Dir.pwd
  end

  after(:each) do
    Dir.chdir(@dir)
  end

  describe 'parse' do
    it 'returns dist config if no config file found' do
      Dir.chdir('./spec/configTest/noConfig')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", [], nil)
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'abort if invalid yaml' do
      Dir.chdir('./spec/configTest/invalidYaml')

      expect { ConfigurationParser.parse(dist_folder: "dist", bootstrap: true).eql(Configuration.new("dist", [], nil)) }
        .to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("unable to pare the .deploy-now/config.yaml config file\n(<unknown>): found unexpected end of stream while scanning a quoted scalar at line 1 column 7".colorize(:red))
      end
    end

    it 'abort if version is missing' do
      Dir.chdir('./spec/configTest/missingVersion')

      expect { ConfigurationParser.parse(dist_folder: "dist", bootstrap: true).eql(Configuration.new("dist", [], nil)) }
        .to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("version must be specified in .deploy-now/config.yaml config file".colorize(:red))
      end
    end

    it 'abort if wrong version is defined' do
      Dir.chdir('./spec/configTest/wrongVersion')

      expect { ConfigurationParser.parse(dist_folder: "dist", bootstrap: true).eql(Configuration.new("dist", [], nil)) }
        .to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("unknown version: 0.1".colorize(:red))
      end
    end

    it 'abort if wrong force is defined' do
      Dir.chdir('./spec/configTest/wrongForce')

      expect { ConfigurationParser.parse(dist_folder: "dist", bootstrap: true).eql(Configuration.new("dist", [], nil)) }
        .to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("only 'bootstrap' or 'recurring' are allowed for deploy.force in .deploy-now/config.yaml".colorize(:red))
      end
    end

    it 'abort if invalid cron job is defined' do
      Dir.chdir('./spec/configTest/invalidCronJob')

      expect { ConfigurationParser.parse(dist_folder: "dist", bootstrap: true) }
        .to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.to_s).to eq("A cron job requires the fields 'command' and 'schedule' in .deploy-now/config.yaml".colorize(:red))
      end
    end

    it 'returns config recurring with exclude' do
      Dir.chdir('./spec/configTest/recurringExcludes')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: false)
      expected_config = Configuration.new("dist", ['var', 'storage/database.sqlite'], nil)
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config recurring with pre_deployment_remote_commands' do
      Dir.chdir('./spec/configTest/recurringPreDeploymentRemoteCommands')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: false)
      expected_config = Configuration.new("dist", [], ["ls -al", "echo \"test\""])

      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config bootstrap with pre- and post_deployment_remote_commands' do
      Dir.chdir('./spec/configTest/bootstrapCommands')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", [], ["ls -al", "echo \"pre\""], ["ls -al", "echo \"post\""])

      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config bootstrap with exclude' do
      Dir.chdir('./spec/configTest/bootstrapExcludes')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", ['var', 'storage/database.sqlite'], nil)
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config with missing deploy' do
      Dir.chdir('./spec/configTest/missingDeploy')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", [], nil)
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config with missing recurring' do
      Dir.chdir('./spec/configTest/recurringNothing')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: false)
      expected_config = Configuration.new("dist", [], nil)
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config with missing recurring' do
      Dir.chdir('./spec/configTest/bootstrapNothing')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", [], nil)
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config with bootstrapForce' do
      Dir.chdir('./spec/configTest/bootstrapForce')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: false)
      expected_config = Configuration.new("dist", ["var/bootstrap"], ["echo \"bootstrap\""])
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config with recurringForce' do
      Dir.chdir('./spec/configTest/recurringForce')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", ["var/recurring"], ["echo \"recurring\""])
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end

    it 'returns config with cronJobs' do
      Dir.chdir('./spec/configTest/cronJobs')
      config = ConfigurationParser.parse(dist_folder: "dist", bootstrap: true)
      expected_config = Configuration.new("dist", [], nil, nil, [{'command' => 'my-command', 'schedule' => '0 5 * * *'}])
      expect(config.eql(expected_config)).to eql(true), "Got #{config}\nexpected #{expected_config}"
    end
  end
end
