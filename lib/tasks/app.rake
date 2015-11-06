namespace :app do
  desc Cluster::RakeDocs.new('app:init').desc
  task init: ['cluster:configtest', 'cluster:config_sync_check'] do
    app = Cluster::App.find_or_create
    puts "App: #{app.name} created"
  end

  desc Cluster::RakeDocs.new('app:delete').desc
  task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::App.delete
  end
end
