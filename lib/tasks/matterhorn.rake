namespace :matterhorn do
  desc 'start matterhorn on all layers configured for app deployment'
  task start: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('mh-opsworks-recipes::start-matterhorn')
  end

  desc 'restart matterhorn on all layers configured for app deployment'
  task restart: ['cluster:configtest', 'cluster:config_sync_check'] do
    # Here's where we can shim in logic to gracefully shut down based on
    # matterhorn activity
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('mh-opsworks-recipes::restart-matterhorn')
  end

  desc 'stop matterhorn on all layers configured for app deployment'
  task stop: ['cluster:configtest', 'cluster:config_sync_check'] do
    # Here's where we can shim in logic to gracefully shut down based on
    # matterhorn activity
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('mh-opsworks-recipes::stop-matterhorn')
  end
end
