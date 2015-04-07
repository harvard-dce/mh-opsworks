shared_examples_for 'a singleton layer for' do |shortname|
  include EnvironmentHelpers

  it "does not raise when all is well with the world" do
    stub_config_to_include(
      { stack: { layers: [layer_with_instances_numbering_for(shortname, 1)] } }
    )

    expect{ described_class.sane? }.not_to raise_error
  end

  it "raises when no layer is defined" do
    stub_config_to_include( { stack: { layers: [] } })

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::LayerNotDefined
    )
  end

  it "raises when more than one #{shortname} layer is defined" do
    layer = layer_with_instances_numbering_for(shortname, 1)

    stub_config_to_include(
      { stack: { layers: [layer, layer] } }
    )

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::TooManyLayers
    )
  end

  it "raises when more than one #{shortname} instance is defined" do
    stub_config_to_include(
      { stack: { layers: [layer_with_instances_numbering_for(shortname, 2)] } }
    )

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::TooManyInstancesInLayer
    )
  end

  it 'raises when no volume_configurations are available' do
    stub_config_to_include(
      {
        stack: {
          layers: [
            {
              shortname: shortname,
              type: 'custom',
              instances: {},
              volume_configurations: []
            }
          ]
        }
      }
    )

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::NoStorageVolumesDefined
    )
  end

  it_behaves_like 'a registered configuration check'

  def layer_with_instances_numbering_for(shortname, number_of_instances)
    {
      name: 'Layer name',
      shortname: shortname,
      instances: {
        number_of_instances: number_of_instances
      },
      volume_configurations: [
        {
          mount_point: "/var/matterhorn",
          raid_level: 0,
          number_of_disks: 2,
          size: "20",
          volume_type: "gp2"
        }
      ]
    }
  end
end
