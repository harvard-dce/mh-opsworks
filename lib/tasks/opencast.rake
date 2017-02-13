namespace :opencast do
  desc Cluster::RakeDocs.new('opencast:start').desc
  task start: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('oc-opsworks-recipes::start-opencast')
  end

  desc Cluster::RakeDocs.new('opencast:restart').desc
  task restart: ['cluster:configtest', 'cluster:config_sync_check'] do
    # Here's where we can shim in logic to gracefully shut down based on
    # opencast activity
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('oc-opsworks-recipes::restart-opencast')
  end

  desc Cluster::RakeDocs.new('opencast:stop').desc
  task stop: ['cluster:configtest', 'cluster:config_sync_check'] do
    # Here's where we can shim in logic to gracefully shut down based on
    # opencast activity
    Cluster::ExecuteRecipeOnDeploymentLayers.execute('oc-opsworks-recipes::stop-opencast')
  end
end
