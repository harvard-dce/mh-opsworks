describe Cluster::Config do
  include EnvironmentHelpers

  context '#credentials' do
    it 'returns an instance of Aws::Credentials' do
      with_valid_json_config do
        config = described_class.new

        expect(config.credentials).to be_instance_of(Aws::Credentials)
      end
    end
  end

  it 'uses cluster_config.json as the config by default' do
    with_modified_env(CLUSTER_CONFIG_FILE: nil) do
      allow(File).to receive(:read)

      described_class.new

      expect(File).to have_received(:read).with('cluster_config.json')
    end
  end

  it 'uses ENV["CLUSTER_CONFIG_FILE"] if defined' do
    with_modified_env(CLUSTER_CONFIG_FILE: 'foobar') do
      allow(File).to receive(:read)

      described_class.new

      expect(File).to have_received(:read).with('foobar')
    end
  end

  context '#sane?' do
    it 'raises Cluster::JSONFormatError on invalid JSON' do
      with_modified_env(
        CLUSTER_CONFIG_FILE: 'spec/support/files/invalid_json.json'
      ) do

        config = described_class.new

        expect{ config.sane? }.to raise_error(Cluster::JSONFormatError)
      end
    end

    it 'is true for valid JSON' do
      with_modified_env(
        CLUSTER_CONFIG_FILE: 'spec/support/files/valid_json.json'
      ) do

        config = described_class.new

        expect(config).to be_sane
      end
    end
  end
end
