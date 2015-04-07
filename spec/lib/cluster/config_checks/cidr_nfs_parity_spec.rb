describe Cluster::ConfigChecks::CidrNfsParity do
  include EnvironmentHelpers

  it 'does not raise when the vpc cidr matches the nfs storage export' do
    stub_config_to_include({
        vpc: {
          cidr_block: '10.0.0.0/24'
        },
        stack:
        { chef: { custom_json: { storage: { network: '10.0.0.0/24' } } }
      }
    })
    expect { described_class.sane? }.not_to raise_error
  end

  it 'raises when the vpc cidr does not match' do
    stub_config_to_include({
        vpc: {
          cidr_block: 'woah dude you do not match'
        },
        stack:
        { chef: { custom_json: { storage: { network: '10.0.0.0/24' } } }
      }
    })

    expect { described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::VpcCidrAndNfsExportMismatch
    )
  end

  it_behaves_like 'a registered configuration check'
end
