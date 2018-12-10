describe Cluster::RemoteConfig do
  include EnvironmentHelpers
  include ClusterCreationHelpers
  include ClientStubHelpers

  context '.create' do
    it 'uses Cluster::ConfigCreator to create the templatted json' do
      config_creator_double = double('Config creator')
      allow(config_creator_double).to receive(:create).and_return('{}')

      allow(Cluster::ConfigCreator).to receive(:new).and_return(config_creator_double)
      allow(File).to receive(:open)
      attributes = {
        name: 'a name',
        cidr_block: '10.1.1.0/24',
        variant: :large
      }
      described_class.create(attributes)

      expect(File).to have_received(:open)
      expect(Cluster::ConfigCreator).to have_received(:new).with(attributes)
      expect(config_creator_double).to have_received(:create)
    end

    it 'writes the config to a file named with a calculated version of the cluster name' do
      allow(Cluster::Assets).to receive(:get_support_asset)
      cluster_name = 'A Test Cluster'

      # so that the AmiFinder request gets stubbed
      stub_ec2_client do |ec2|
        ec2.stub_responses(
            :describe_images,
            { images: [ ] }
        )
      end

      file_double = double('file handle')
      allow(file_double).to receive(:write)
      allow(File).to receive(:open).and_return(file_double)

      described_class.create(dummy_cluster_attributes.merge(name: cluster_name))

      expect(File).to have_received(:open).with('cluster_config-a-test-cluster.json', 'w', 0600)
    end
  end

  context '#download' do
    it 'gets the remote content and saves to the correct file' do
      with_no_ocopsworks_rc do
        with_mocked_content(local: '', remote: '') do |remote_config|
          allow(remote_config).to receive(:remote_config_contents)
          allow(File).to receive(:open)
          remote_config.download

          expect(remote_config).to have_received(:remote_config_contents)
          expect(File).to have_received(:open).with(Cluster::Config.new.active_config, 'w', 0600)
        end
      end
    end
  end

  context '#config_state' do
    it ':current if there are no differences and our versions are the same' do
      content = %Q|{"version": 1000, "key": "value 1"}\n|
      config_double = double('config')
      allow(config_double).to receive(:version).and_return(1000)
      allow(Cluster::Config).to receive(:new).and_return(config_double)

      with_mocked_content( local: content, remote: content) do |remote_config|
        expect(remote_config.config_state).to eq :current
      end
    end

    it ':behind_remote if the remote version number is greater than ours' do
      local_content = %Q|{"version": 1000, "key": "value 1"}\n|
      remote_content = %Q|{"version": 1001, "key": "value 1"}\n|
      config_double = double('config')
      allow(config_double).to receive(:version).and_return(1000)
      allow(Cluster::Config).to receive(:new).and_return(config_double)

      with_mocked_content( local: local_content, remote: remote_content ) do |remote_config|
        expect(remote_config.config_state).to eq :behind_remote
      end
    end

    it ':newer_than_remote if the versions are the same and we have changes' do
      local_content = %Q|{"version": 1000, "key": "value 2"}\n|
      remote_content = %Q|{"version": 1000, "key": "value 1"}\n|
      config_double = double('config')
      allow(config_double).to receive(:version).and_return(1000)
      allow(Cluster::Config).to receive(:new).and_return(config_double)

      with_mocked_content( local: local_content, remote: remote_content ) do |remote_config|
        expect(remote_config.config_state).to eq :newer_than_remote
      end
    end

    it ':newer_than_remote if the remote version is nil' do
      local_content = %Q|{"version": 1000, "key": "value 2"}\n|
      remote_content = nil
      config_double = double('config')
      allow(config_double).to receive(:version).and_return(1000)
      allow(Cluster::Config).to receive(:new).and_return(config_double)

      with_mocked_content( local: local_content, remote: remote_content ) do |remote_config|
        expect(remote_config.config_state).to eq :newer_than_remote
      end

    end
  end

  context '#local_version' do
    it 'gets the version from the local active config' do
      config_double = double('config')
      allow(config_double).to receive(:version).and_return(1000)
      allow(Cluster::Config).to receive(:new).and_return(config_double)

      remote_config = Cluster::RemoteConfig.new
      expect(remote_config.local_version).to eq 1000
    end
  end

  context '#remote_version' do
    it 'uses Cluster::Assets to get the file' do
      cluster_config_bucket_name = 'config_bucket'
      allow(Cluster::Assets).to receive(:get_support_asset)
      stub_configs_with_bucket_and_stack_name(
        cluster_config_bucket_name,
        'test cluster'
      )
      client = described_class.new

      client.remote_version

      expect(Cluster::Assets).to have_received(:get_support_asset).with(
        file_name: 'cluster_config-test-cluster.json',
        bucket: cluster_config_bucket_name
      )
    end

    it 'gets the version from the remote config' do
      client = described_class.new
      allow(client).to receive(:remote_config_contents).and_return(
        '{ "version": "1000" }'
      )

      expect(client.remote_version).to eq 1000
    end

    it 'returns nil if there is no remote config' do
      client = described_class.new
      allow(client).to receive(:remote_config_contents)

      expect(client.remote_version).to be nil
    end
  end

  context '#delete' do
    it 'uses Cluster::Assets to delete the file' do
      stub_rc_switcher
      stub_config_deletion
      bucket_name = 'bucket_name'
      stack_name = 'test stack'
      stub_configs_with_bucket_and_stack_name(bucket_name, stack_name)
      allow(Cluster::Assets).to receive(:delete_support_asset)
      allow(Cluster::VPC).to receive(:find_existing).and_return(nil)

      client = described_class.new

      client.delete

      expect(Cluster::Assets).to have_received(:delete_support_asset).with(
        bucket: bucket_name,
        file_name: 'cluster_config-test-stack.json'
      )
    end

    it 'raises if the stack exists' do
      stub_rc_switcher
      stub_config_deletion
      vpc_double = double('vpc')

      allow(Cluster::VPC).to receive(:find_existing).and_return(vpc_double)
      allow(Cluster::Assets).to receive(:delete_support_asset)

      client = described_class.new

      expect { client.delete }.to raise_error(Cluster::RemoteConfig::StillExists)
    end

    it 'deletes the rc file' do
      rc_switcher_double = stub_rc_switcher
      stub_config_deletion

      allow(Cluster::VPC).to receive(:find_existing).and_return(nil)
      allow(Cluster::Assets).to receive(:delete_support_asset)

      described_class.new.delete

      expect(File).to have_received(:unlink)
    end
  end

  context '#changeset' do
    it 'shows a diff against the upstream cluster config' do
      with_mocked_content(
        local: %Q|{"version": 1001, "key": "value 2"}\n|,
        remote: %Q|{"version": 1000, "key": "value 1"}\n|
      ) do |remote_config|
        diff = remote_config.changeset

        expect(diff.to_s).to eq %Q|-{"version": 1000, "key": "value 1"}\n+{"version": 1001, "key": "value 2"}\n|
      end
    end
  end

  context '#changed?' do
    it 'is true if there are differences' do
      with_mocked_content(
        local: %Q|{"version": 1001, "key": "value 2"}\n|,
        remote: %Q|{"version": 1000, "key": "value 1"}\n|
      ) do |remote_config|
        diff = remote_config.changeset

        expect(remote_config.changed?).to be true
      end
    end

    it 'is false if they are the same' do
      config_content = 'asdf'
      with_mocked_content(
        local: config_content,
        remote: config_content
      ) do |remote_config|
        expect(remote_config.changed?).to be false
      end
    end
  end

  context '#sync' do
    it 'saves the config to the local file with an incremented version' do
      config_file = 'spec/support/files/minimal_config.json'
      with_no_ocopsworks_rc do
        with_retained_config_file(config_file) do
          with_modified_env(CLUSTER_CONFIG_FILE: config_file) do
            allow(Cluster::Assets).to receive(:publish_support_asset_to)
            config = Cluster::Config.new
            remote_config = described_class.new
            remote_config.sync

            expect(Cluster::Config.new.version).to eq 1001
            expect(JSON.parse(File.read(config_file))['version']).to eq 1001
          end
        end
      end
    end

    it 'uses Cluster::Assets to save the current cluster_config' do
      config_file = 'spec/support/files/minimal_config.json'
      with_no_ocopsworks_rc do
        with_retained_config_file(config_file) do
          with_modified_env(CLUSTER_CONFIG_FILE: config_file) do
            allow(Cluster::Assets).to receive(:publish_support_asset_to)
            config = Cluster::Config.new
            remote_config = described_class.new
            remote_config.sync

            expect(Cluster::Assets).to have_received(
              :publish_support_asset_to
            ).with(hash_including( file_name: config_file))
          end
        end
      end

    end
  end

  def stub_configs_with_bucket_and_stack_name(bucket, stack_name)
    stub_config_to_include(
      stack: {
        name: stack_name,
        chef: {
          custom_json: {
          }
        }
      }
    )
    stub_secrets_to_include(
      cluster_config_bucket_name: bucket
    )
  end

  def stub_config_deletion
    allow(File).to receive(:unlink)
  end

  def stub_rc_switcher
    double('rc switcher').tap do |rc_switcher_double|
      allow(rc_switcher_double).to receive(:delete)
      allow(Cluster::RcFileSwitcher).to receive(:new).and_return(rc_switcher_double)
    end
  end

  def with_mocked_content(local: '', remote: '')
    remote_config = described_class.new
    allow(remote_config).to receive(:remote_config_contents).and_return(remote)
    allow(remote_config).to receive(:local_config_contents).and_return(local)

    yield remote_config
  end

  def with_mocked_versions(local: '', remote: '')
    remote_config = described_class.new
    allow(remote_config).to receive_messages(
      remote_version: remote,
      local_version: local
    )

    yield remote_config
  end
end
