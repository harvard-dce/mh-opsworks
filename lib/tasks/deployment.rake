namespace :deployment do
  desc 'deploy the main application'
  task deploy_app: ['cluster:configtest'] do
    Cluster::Deployment.deploy_app
  end

  desc 'list recent deployments'
  task list: ['cluster:configtest'] do

  end
end
