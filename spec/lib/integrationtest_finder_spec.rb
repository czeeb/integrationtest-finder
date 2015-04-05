require_relative '../../lib/integrationtest_finder.rb'

RSpec.describe IntegrationtestFinder do
  describe 'fetch_targets' do
    it 'returns 0 element array after initial instantiation' do
      testrunner = IntegrationtestFinder.new
      expect(testrunner.fetch_targets).to be_empty
      expect(testrunner.fetch_targets).to be_kind_of(Array)
    end
  end

  describe 'add_to_targets', fakefs: true do
    def stub_filesystem
      FileUtils.mkdir_p('/tmp/cookbook1/serverspec')
      FileUtils.mkdir_p('/tmp/cookbook2/serverspec')

      FileUtils.touch('/tmp/cookbook1/serverspec/default_spec.rb')
      FileUtils.touch('/tmp/cookbook1/serverspec/server_spec.rb')
      FileUtils.touch('/tmp/cookbook1/serverspec/client_spec.rb')

      FileUtils.touch('/tmp/cookbook2/serverspec/default_spec.rb')
    end

    it 'adds directories which should contain serverspec tests' do
      stub_filesystem

      testrunner = IntegrationtestFinder.new
      testrunner.add_to_targets('/tmp/cookbook1/serverspec')
      testrunner.add_to_targets('/tmp/cookbook2/serverspec')
      expect(testrunner.fetch_targets).to_not be_empty
      expect(testrunner.fetch_targets.count).to eq(2)
    end
  end
end
