module Cluster
  class ExecuteRecipeOnDeploymentLayers
    def self.execute(recipe)
      layers = Cluster::Base.deployment_config[:to_layers]
      Cluster::Deployment.execute_chef_recipes_on_layers(
        recipes: [ recipe ],
        layers: layers
      )
    end
  end
end
