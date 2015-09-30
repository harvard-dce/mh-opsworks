namespace :deployment do
  desc 'deploy the main application'
  task deploy_app: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.deploy_app
  end

  desc 'force deploy the most recent commit on the configured app revision'
  task redeploy_app: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.redeploy_app
  end

  task rollback_app: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Deployment.rollback_app
  end

  desc 'list recent deployments'
  task list: ['cluster:configtest', 'cluster:config_sync_check'] do
    puts 'Deployments: '
    Cluster::Deployment.all.each do |deployment|
      recipe_output = ''
      if deployment.command.name == 'execute_recipes'
        recipe_output = ' - ' + deployment.command.args['recipes'].join(',')
      end
      puts %Q|#{deployment.command.name}#{recipe_output}, #{deployment.status}, started: #{deployment.created_at}, duration: #{deployment.duration} seconds, by: #{deployment.iam_user_arn}|

    end
  end
end
