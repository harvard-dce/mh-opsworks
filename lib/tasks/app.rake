namespace :app do
  desc 'Initialize app'
  task init: ['cluster:configtest', 'cluster:config_sync_check'] do
    app = Cluster::App.find_or_create
    puts "App: #{app.name} created"
  end

  desc 'Delete app'
  task delete: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::App.delete
  end
end
