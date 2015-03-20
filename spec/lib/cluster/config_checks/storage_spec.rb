describe Cluster::ConfigChecks::Storage do
  include EnvironmentHelpers

  it "does not raise when all is well with the world" do
    stub_config_to_include(
      { stack: { layers: [storage_layer_with_instances_numbering(1)] } }
    )

    expect{ described_class.sane? }.not_to raise_error
  end

  it "raises when no layer is defined" do
    stub_config_to_include( { stack: { layers: [] } })

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::LayerNotDefined
    )
  end

  it "raises when more than one storage layer is defined" do
    storage_layer = storage_layer_with_instances_numbering(1)

    stub_config_to_include(
      { stack: { layers: [storage_layer, storage_layer] } }
    )

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::TooManyLayers
    )
  end

  it "raises when more than one storage instance is defined" do
    stub_config_to_include(
      { stack: { layers: [storage_layer_with_instances_numbering(2)] } }
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
              shortname: 'storage',
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

  def storage_layer_with_instances_numbering(number_of_instances)
    {
      shortname: 'storage',
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
