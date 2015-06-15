namespace :cluster do
  desc 'Sanity check your cluster configuration'
  task :configtest do
    config = Cluster::Config.new
    if config.active_config == 'templates/cluster_config_default.json.erb'
      puts "\nYou don't have a valid cluster active. You have two options:
* Use 'cluster:switch' to switch into one, or
* Run 'cluster:new' to create and switch into a new one.

"
      exit 1
    end
    config.sane?
  end

  desc "get info on the cluster we're currently working in"
  task :active do
    remote_config = Cluster::RemoteConfig.new
    puts %Q|\nCurrently managing: "#{Cluster::Base.stack_config[:name]}" : #{remote_config.active_cluster_config_name}\n|
  end

  desc 'checks that the cluster config is up to date'
  task :config_sync_check do
    remote_config = Cluster::RemoteConfig.new

    config_state = remote_config.config_state
    puts %Q|\nCurrently managing: "#{Cluster::Base.stack_config[:name]}" : #{remote_config.active_cluster_config_name}\n|
    if config_state == :current
      puts "Our local config file is up to date"
    elsif config_state == :behind_remote
      puts "Updating to the latest config file"
      remote_config.download
    else
      puts "\nYour config is ahead of upstream - changes below:\n\n"
      puts remote_config.changeset
      print "Sync these changes? (y or n): "
      answer = STDIN.gets.chomp

      if ['y','Y'].include?(answer)
        remote_config.sync
      else
        puts "Quitting. Please resolve your config changes and try again."
        exit
      end
    end
  end

  desc 'a ruby console'
  task console: [:configtest, :config_sync_check] do
    Cluster::Console.run
  end

  desc 'Initialize and switch into a new cluster config'
  task :new do
    session = Cluster::ConfigCreationSession.new
    session.choose_variant
    session.get_cluster_name
    session.get_git_url
    session.get_git_revision
    session.compute_cidr_block_root

    config_file = Cluster::RemoteConfig.create(
      name: session.name,
      variant: session.variant,
      cidr_block_root: session.cidr_block_root,
      app_git_url: session.git_url,
      app_git_revision: session.git_revision
    )
    rc_file = Cluster::RcFileSwitcher.new(config_file: config_file)
    rc_file.write

    Cluster::RemoteConfig.new.sync
  end

  desc 'switch to start working with a different cluster'
  task :switch do
    session = Cluster::ClusterSwitcherSession.new

    if ! session.configs.any?
      puts 'No clusters yet.'
      exit
    end

    session.choose_cluster
  end

  task :migrate_legacy_config do
    if File.exists?('cluster_config.json')
      fixed_name = Cluster::RemoteConfig.new.active_cluster_config_name
      FileUtils.mv('cluster_config.json', fixed_name)
      rc_file = Cluster::RcFileSwitcher.new(config_file: fixed_name)
      rc_file.write

      Cluster::RemoteConfig.new.sync
    end
  end
end
