describe Cluster::ConfigChecks::Storage do
  include EnvironmentHelpers

  it_behaves_like 'a singleton layer for', 'storage'

  context 'an external NFS server is configured' do
    context 'and there is no storage layer' do
      it 'does not raise if type is "external"' do
        stub_config_to_include(
          {
            stack: {
              chef: { custom_json: {
                storage: {
                  type: 'external',
                  export_root: '/var/opencast',
                  nfs_server_host: '10.0.0.1'
                }
              }},
              layers: [] }
          }
        )
        expect{ described_class.sane? }.not_to raise_error
      end

      it 'raises if there is no nfs_server_host' do
        stub_config_to_include(
          {
            stack: {
              chef: { custom_json: {
                storage: {
                  type: 'external',
                  export_root: '/var/opencast',
                }
              }},
              layers: [] }
          }
        )
        expect{ described_class.sane? }.to raise_error(
          Cluster::ConfigChecks::NoNfsServerHost
        )
      end
    end

    context 'and a storage layer is configured' do
      it 'raises an error' do
        stub_config_to_include(
          {
            stack: {
              chef: {
                custom_json: {
                  storage: {
                    type: 'external',
                    nfs_server_host: 'foo.example'
                  }
                }
              },
              layers: [
                { name: 'Layer name',
                  shortname: 'storage',
                  instances: { number_of_instances: 1 },
                  volume_configurations: [
                    { mount_point: '/var/opencast', number_of_disks: 1, size: '10' }
                  ]
              }
              ]
            }
          }
        )

        expect{ described_class.sane? }.to raise_error(
          Cluster::ConfigChecks::ConflictingStorageConfiguration
        )
      end
    end
  end
end
