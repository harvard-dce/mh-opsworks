namespace :matterhorn do
  desc Cluster::RakeDocs.new('matterhorn:start').desc
  task start: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('mh-opsworks-recipes::start-matterhorn')
  end

  desc Cluster::RakeDocs.new('matterhorn:restart').desc
  task restart: ['cluster:configtest', 'cluster:config_sync_check'] do
    # Here's where we can shim in logic to gracefully shut down based on
    # matterhorn activity
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('mh-opsworks-recipes::restart-matterhorn')
  end

  desc Cluster::RakeDocs.new('matterhorn:stop').desc
  task stop: ['cluster:configtest', 'cluster:config_sync_check'] do
    # Here's where we can shim in logic to gracefully shut down based on
    # matterhorn activity
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('mh-opsworks-recipes::stop-matterhorn')
  end
end
