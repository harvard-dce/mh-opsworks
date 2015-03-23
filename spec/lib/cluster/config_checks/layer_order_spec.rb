describe Cluster::ConfigChecks::LayerOrder do
  include EnvironmentHelpers
  it 'does not raise when layers are defined in the right order' do
    stub_config_to_include(
      {
        stack: {
          layers: [ db_layer, storage_layer, another_layer ]
        }
      }
    )
    expect{ described_class.sane? }.not_to raise_error
  end

  it 'raises when the db layer is late' do
    stub_config_to_include(
      {
        stack: {
          layers: [storage_layer, another_layer, db_layer]
        }
      }
    )
    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::DatabaseLayerLate
    )
  end

  it 'raises when the storage layer is late' do
    stub_config_to_include(
      {
        stack: {
          layers: [db_layer, another_layer, storage_layer]
        }
      }
    )
    expect{ described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::StorageLayerLate
    )
  end

  it_behaves_like 'a registered configuration check'

  def db_layer
    { name: 'DB Layer', type: 'db-master' }
  end

  def storage_layer
    { name: 'Storage', shortname: 'storage' }
  end

  def another_layer
    { name: 'Another layer', shortname: 'another-layer' }
  end
end
