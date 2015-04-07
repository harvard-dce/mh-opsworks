describe Cluster::ConfigChecks::Deployment do
  include EnvironmentHelpers

  it 'does not raise when all layers are present' do
    stub_config_to_include(
      { stack: deployment_to_layers }
    )

    expect { described_class.sane? }.not_to raise_error
  end

  it 'raises when a base layer is not deployed to defaultly' do
    stub_config_to_include(
      { stack: deployment_to_layers(['Admin']) }
    )

    expect { described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::NotAllBaseLayersDeployedTo
    )
  end

  it_behaves_like 'a registered configuration check'

  def deployment_to_layers(layers = ["Admin", "Engage", "Workers", "MySQL db"])
    {
      app: {
        shortname: "matterhorn",
        name: "Matterhorn",
        type: "other",
        deployment: {
          to_layers: layers,
          custom_json: { }
        },
        app_source: {
          type: "git",
          url: "git@bitbucket.org:hudcede/matterhorn-dce-fork.git",
          revision: "master"
        }
      }
    }
  end
end
