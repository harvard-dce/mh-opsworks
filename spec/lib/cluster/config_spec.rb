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
    it 'uses the check_registry' do
      with_valid_json_config do
        allow(described_class).to receive(:check_registry).and_return([])

        described_class.new.sane?

        expect(described_class).to have_received(:check_registry)
      end
    end
  end
end
