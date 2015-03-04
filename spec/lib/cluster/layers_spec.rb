describe Cluster::Layers do
  include EnvironmentHelpers
  context '.all' do
    it 'uses the Stack to find layers' do
      find_double = double('find_or_create')
      allow(find_double).to receive(:layers).and_return([])
      allow(Cluster::Stack).to receive(:find_or_create).and_return(find_double)

      described_class.all

      expect(find_double).to have_received(:layers)
    end
  end

  context '.find_or_create' do
    it 'uses Cluster::Layer to find or create layers' do
      allow(Cluster::Layer).to receive(:find_or_create)
      layer = { name: 'a name'}

      stub_config_to_include(
        stack: {
          layers: [ layer ]
        }
      )

      described_class.find_or_create

      expect(Cluster::Layer).to have_received(:find_or_create).with(layer)
    end
  end
end
