describe Cluster::ConfigChecks::JsonFormat do
  include EnvironmentHelpers

  it 'raises Cluster::JSONFormatError on invalid JSON' do
    with_modified_env(
      CLUSTER_CONFIG_FILE: 'spec/support/files/invalid_json.json'
    ) do

      expect{ described_class.sane? }.to raise_error(Cluster::ConfigChecks::JSONFormatError)
    end
  end

  it 'is true for valid JSON' do
    with_modified_env(
      CLUSTER_CONFIG_FILE: 'spec/support/files/valid_json.json'
    ) do

      expect(described_class).to be_sane
    end
  end

end
