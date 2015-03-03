namespace :cluster do
  desc 'Sanity check cluster_config.json'
  task :configtest do
    config = Cluster::Config.new
    if config.sane?
      puts 'Pre-flight looks good.'
    end
  end

  desc 'a ruby console'
  task console: [:configtest] do
    Cluster::Console.run
  end
end
