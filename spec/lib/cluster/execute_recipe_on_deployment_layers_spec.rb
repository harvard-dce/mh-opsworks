describe Cluster::ExecuteRecipeOnDeploymentLayers do
  include EnvironmentHelpers
  include ClientStubHelpers

  it 'uses the deployment config' do
    recipe = 'a recipe'
    layer = 'a layer'
    stub_config_to_include_layers([layer])
    allow(Cluster::Deployment).to receive(:execute_chef_recipes_on_layers)

    described_class.execute(recipe)

    expect(Cluster::Deployment).to have_received(:execute_chef_recipes_on_layers).with(
      recipes: [ recipe ],
      layers: [ layer ]
    )
  end

  def stub_config_to_include_layers(layers)
    stub_config_to_include(
      stack: {
        app: {
          deployment: {
            to_layers: layers
          }
        }
      }
    )
  end
end
