namespace :cluster do
  desc 'Sanity check cluster_config.json'
  task :configtest do
    config = Cluster::Config.new
    config.sane?
  end

  desc 'a ruby console'
  task console: [:configtest] do
    Cluster::Console.run
  end
end
