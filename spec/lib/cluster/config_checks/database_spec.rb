describe Cluster::ConfigChecks::Database do
  include EnvironmentHelpers

  it "does not raise when all is well with the world" do
    stub_config_to_include(
      { stack: { layers: [database_layer_with_instances_numbering(1)] } }
    )

    expect{ described_class.sane? }.not_to raise_error
  end

  it "raises when no layer is defined" do
    stub_config_to_include( { stack: { layers: [] } })

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::DatabaseMasterLayerNotDefined
    )
  end

  it "raises when more than one database layer is defined" do
    database_layer = database_layer_with_instances_numbering(1)

    stub_config_to_include(
      { stack: { layers: [database_layer, database_layer] } }
    )

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::TooManyDatabaseLayers
    )
  end

  it "raises when more than one database instance is defined" do
    stub_config_to_include(
      { stack: { layers: [database_layer_with_instances_numbering(2)] } }
    )

    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::TooManyInstancesInDatabaseMasterLayer
    )
  end

  def database_layer_with_instances_numbering(number_of_instances)
    {
      name: 'DB layer',
      type: 'db-master',
      instances: {
        number_of_instances: number_of_instances
      }
    }
  end
end
