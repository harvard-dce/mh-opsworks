namespace :deployment do
  desc 'deploy the main application'
  task deploy_app: ['cluster:configtest'] do
    Cluster::Deployment.deploy_app
  end

  desc 'list recent deployments'
  task list: ['cluster:configtest'] do
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
