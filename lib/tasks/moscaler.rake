namespace :moscaler do
  desc Cluster::RakeDocs.new('moscaler:pause').desc
  task pause: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.execute_chef_recipes_on_layers(
        recipes: [ "oc-opsworks-recipes::moscaler-pause" ],
        layers: ["Ganglia"]
    )
  end

  desc Cluster::RakeDocs.new('moscaler:resume').desc
  task resume: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.execute_chef_recipes_on_layers(
        recipes: [ "oc-opsworks-recipes::moscaler-resume" ],
        layers: ["Ganglia"]
    )
  end
end
