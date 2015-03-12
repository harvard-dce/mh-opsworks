namespace :app do
  desc 'Initialize app'
  task init: ['cluster:configtest'] do
    app = Cluster::App.find_or_create
    puts "App: #{app.name} created"
  end

  desc 'Delete app'
  task delete: ['cluster:configtest'] do
    Cluster::App.delete
  end
end
