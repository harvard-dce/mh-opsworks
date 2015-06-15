describe Cluster::Config do
  include EnvironmentHelpers

  context '#credentials' do
    it 'returns an instance of Aws::Credentials' do
      with_valid_json_config do
        config = described_class.new

        expect(config.credentials).to be_instance_of(Aws::Credentials)
      end
    end
  end


  it 'uses templates/cluster_config_default.json.erb as the config by default' do
    with_no_mhopsworks_rc do
      with_modified_env(CLUSTER_CONFIG_FILE: nil) do
        allow(File).to receive(:read)

        described_class.new

        expect(File).to have_received(:read).with('templates/cluster_config_default.json.erb')
      end
    end
  end

  it 'uses ENV["CLUSTER_CONFIG_FILE"] if defined' do
    config_file = 'spec/support/files/minimal_config.json'
    with_no_mhopsworks_rc do
      with_modified_env(CLUSTER_CONFIG_FILE: config_file) do
        allow(File).to receive(:read)

        described_class.new

        expect(File).to have_received(:read).with(config_file)
      end
    end
  end

  context '#version' do
    it 'casts to an integer' do
      config = described_class.new

      allow(config).to receive(:parsed).and_return({version: '1000'})

      expect(config.version).to eq 1000
    end
  end

  context '#sane?' do
    it 'uses the check_registry' do
      with_valid_json_config do
        allow(described_class).to receive(:check_registry).and_return([])

        described_class.new.sane?

        expect(described_class).to have_received(:check_registry)
      end
    end
  end
end

describe 'with .mhopsworks.rc' do
  include EnvironmentHelpers

  it 'reads from .mhopsworks.rc to determine the active cluster' do
    with_modified_env(CLUSTER_CONFIG_FILE: nil) do
      with_overwritten_mhopsworks_rc do
        config = Cluster::Config.new

        expect(config.parsed).to eq({ key: 'test-cluster.json'})
      end
    end
  end

  it 'reads from .mhopsworks.rc to determine the active secrets.json' do
    with_modified_env(SECRETS_FILE: nil) do
      with_overwritten_mhopsworks_rc do
        config = Cluster::Config.new

        expect(config.parsed_secrets).to eq({key: 'test-secrets.json'})
      end
    end
  end

  def with_overwritten_mhopsworks_rc
    original_content = nil
    rc_file = '.mhopsworks.rc'
    if File.exists?(rc_file)
      original_content = File.read(rc_file)
    end

    ['test-cluster.json', 'test-secrets.json'].each do |file|
      File.open(file, 'w') do |f|
        f.write({ key: file }.to_json)
      end
    end

    File.open('.mhopsworks.rc', 'w') do |f|
      f.write "cluster=test-cluster.json\n"
      f.write "secrets=test-secrets.json\n"
    end

    begin
      yield
    ensure
      if original_content
        File.open(rc_file, 'w') do |f|
          f.write original_content
        end
      else
        File.unlink(rc_file)
      end
      File.unlink('test-cluster.json')
      File.unlink('test-secrets.json')
    end
  end
end
