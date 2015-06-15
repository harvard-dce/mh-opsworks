describe Cluster::RemoteConfigs do
  include ClientStubHelpers
  include EnvironmentHelpers

  context '.all' do
    it 'returns a list of remotely stored configs in a bucket' do
      stub_s3_client do |client|
        client.stub_responses(
          :list_objects,
          {
            contents: [
              { key: 'foobar' }
            ]
          }
        )
      end

      objects = described_class.all

      expect(objects).to eq ['foobar']
    end
  end

  context '.find' do
    it 'uses .all to find cluster configs' do
      name = 'Cluster of concern'
      with_a_config_named(name) do
        described_class.find(name)
        expect(described_class).to have_received(:all)
      end
    end

    it 'matches cluster configs by their name' do
      name = 'Cluster of concern'
      with_a_config_named(name) do
        config = described_class.find(name)
        expect(config[:name]).to eq name
      end
    end
  end

  def with_a_config_named(name)
    cluster_configs = [
      cluster_config_with_name(name),
      cluster_config_with_name('unwanted')
    ]
    allow(described_class).to receive(:all).and_return(cluster_configs)

    yield
  end

  def cluster_config_with_name(name)
    {
      name: name,
      layers: [],
      stack: []
    }
  end
end
