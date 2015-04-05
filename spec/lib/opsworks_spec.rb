require 'rubygems'
require_relative '../../lib/opsworks/opsworks'

RSpec.describe IntegrationtestFinder::Opsworks do
  before(:each) do
    Aws.config[:stub_responses] = true
  end

  describe 'find_serverspecs', fakefs: true do
    def stub_filesystem
      FileUtils.mkdir_p('/etc/aws/opsworks')
      File.open('/etc/aws/opsworks/instance-agent.yml', 'w') do |f|
        f.puts('---')
        f.puts(':identity: a0a2c947-a031-4019-a362-85e4485ec4f4')
      end

      FileUtils.mkdir_p('/opt/aws/opsworks/current/merged-cookbooks/cookbook1/test/integration/default/serverspec/')
      FileUtils.mkdir_p('/opt/aws/opsworks/current/merged-cookbooks/cookbook2/test/integration/default/serverspec/')
      FileUtils.mkdir_p('/opt/aws/opsworks/current/merged-cookbooks/cookbook3/test/integration/server/serverspec/')

      # aws sdk needs to access some files from its gem
      # so we copy the entire gem into the fake filesystem
      #
      # @TODO: Do not hard code the gem version
      #
      awssdk_gem_dir = Gem.dir + '/gems/aws-sdk-2.0.31'
      FakeFS::FileSystem.clone(awssdk_gem_dir)
      awssdkcore_gem_dir = Gem.dir + '/gems/aws-sdk-core-2.0.31'
      FakeFS::FileSystem.clone(awssdkcore_gem_dir)
    end

    def stub_awssdk
      client = Aws::OpsWorks::Client.new
      client.stub_responses(:describe_instances, instances: [{
        layer_ids: ['b9a2c947-a031-4019-a362-85e4485ec4f4']
      }])

      client.stub_responses(:describe_layers, layers: [{
        custom_recipes: {
          setup:      ['cookbook2'],
          configure:  ['cookbook1', 'cookbook2', 'cookbook3::server'],
          deploy:     ['cookbook1::deploy'],
          undeploy:   [],
          shutdown:   ['cookbook1']
        }
      }])

      client
    end

    it 'fetchs list of directories where serverspec files live' do
      stub_filesystem

      testrunner = IntegrationtestFinder::Opsworks.new
      testrunner.client = stub_awssdk
      testrunner.find_serverspecs

      expect(testrunner.fetch_targets).to_not be_empty
      expect(testrunner.fetch_targets).to contain_exactly(
        '/opt/aws/opsworks/current/merged-cookbooks/cookbook1/test/integration/default/serverspec',
        '/opt/aws/opsworks/current/merged-cookbooks/cookbook2/test/integration/default/serverspec',
        '/opt/aws/opsworks/current/merged-cookbooks/cookbook3/test/integration/server/serverspec'
      )
      expect(testrunner.fetch_targets.count).to eq(3)
    end
  end
end
