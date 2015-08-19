describe Cluster::Layers do
  include EnvironmentHelpers
  context '.all' do
    it 'uses the Stack to find layers' do
      find_double = stub_stack_finder

      described_class.all

      expect(find_double).to have_received(:layers)
    end
  end

  context '.find_or_create' do
    it 'uses Cluster::Layer to find or create layers' do
      find_double = stub_stack_finder
      allow(Cluster::Layer).to receive(:find_or_create)
      layer = { name: 'a name'}

      stub_config_to_include(
        stack: {
          layers: [ layer ]
        }
      )

      described_class.find_or_create

      expect(Cluster::Layer).to have_received(:find_or_create).with(find_double, layer)
    end
  end

  def stub_stack_finder
    double('find_or_create').tap do |find_double|
      allow(find_double).to receive(:layers).and_return([])
      allow(Cluster::Stack).to receive(:with_existing_stack).and_return(find_double)
    end
  end
end
