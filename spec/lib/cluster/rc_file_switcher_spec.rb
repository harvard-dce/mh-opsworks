describe Cluster::RcFileSwitcher do
  it 'unsets ENV["CLUSTER_CONFIG_FILE"] when a config is written' do
    ENV['SECRETS_FILE'] = 'something'
    ENV['CLUSTER_CONFIG_FILE'] = 'another thing'

    config_file = 'config'
    secrets_file = 'secrets'
    switcher = described_class.new(
      config_file: config_file,
      secrets_file: secrets_file
    )
    allow(File).to receive(:open)

    switcher.write

    expect(ENV['SECRETS_FILE']).to eq 'something'
    expect(ENV['CLUSTER_CONFIG_FILE']).not_to be
  end
end
