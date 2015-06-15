describe Cluster::ConfigChecks::BucketConfigs do
  include EnvironmentHelpers

  it 'does not raise when the correct buckets are defined' do
    stub_secrets_to_include({
      stack: {
        secrets: {
          shared_asset_bucket_name: 'foo',
          cluster_config_bucket_name: 'foobar'
        }
      }
    })

    expect { described_class.sane? }.not_to raise_error
  end

  it 'raises when the asset bucket is not defined' do
    stub_secrets_to_include({
      stack: {
        secrets: {
          cluster_config_bucket_name: 'foobar'
        }
      }
    })

    expect { described_class.sane?  }.to raise_error(Cluster::ConfigChecks::NoSharedAssetBucketName)
  end

  it 'raises when the cluster_config bucket is not defined' do
    stub_secrets_to_include({
      stack: {
        secrets: {
          shared_asset_bucket_name: 'asdfasdf'
        }
      }
    })

    expect { described_class.sane?  }.to raise_error(Cluster::ConfigChecks::NoClusterConfigBucketName)
  end

  it_behaves_like 'a registered configuration check'
end
