namespace :deployment do
  desc Cluster::RakeDocs.new('deployment:deploy_app').desc
  task deploy_app: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.deploy_app
  end

  desc Cluster::RakeDocs.new('deployment:redeploy_app').desc
  task redeploy_app: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::Deployment.redeploy_app
  end

  desc Cluster::RakeDocs.new('deployment:redeploy_app_with_unit_tests').desc
  task redeploy_app_with_unit_tests: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::Deployment.redeploy_app_with_unit_tests
  end

  task rollback_app: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.rollback_app
  end

  desc Cluster::RakeDocs.new('deployment:list').desc
  task list: ['cluster:configtest', 'cluster:config_sync_check'] do
    puts 'Deployments: '
    Cluster::Deployment.all.reverse.each do |deployment|
      recipe_output = ''
      if deployment.command.name == 'execute_recipes'
        recipe_output = deployment.command.args['recipes'].join(', ')
      end
      puts %Q|#{deployment.created_at} - #{deployment.command.name} - #{deployment.status}
  executed:	#{recipe_output}
  duration:	#{deployment.duration} seconds
  by:		#{deployment.iam_user_arn}

|
    end
  end
end
