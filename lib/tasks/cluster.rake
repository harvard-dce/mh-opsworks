namespace :cluster do
  task :production_failsafe do
    config = Cluster::Config.new
    stack_name = config.parsed[:stack][:name]
    if stack_name.match(/prod|prd|stage|stg/i)
      puts
      puts "CAUTION! You've chosen a destructive action that could lead to downtime or permanent data loss."
      puts "Type the full stack name below and hit enter to confirm, or just hit enter to abort."
      puts
      print "CONFIRM: "
      answer = STDIN.gets.strip.chomp

      if answer != stack_name
        exit 1
      end
    end
  end

  task :reset_or_seed_check do
    unless Cluster::Base.dev_or_testing_cluster?
      puts
      puts "You're trying to create or apply a cluster seed and we're not certain"
      puts "if you're on a development or testing cluster or not."
      puts 
      puts 'If you are, Please set "cluster_env" to "development" or "test" in your'
      puts "cluster configuration's custom_json and try again."
      puts
      exit 1
    end
  end

  desc Cluster::RakeDocs.new('cluster:configtest').desc
  task :configtest do
    config = Cluster::Config.new
    if config.active_config == 'templates/minimal_cluster_config.json'
      puts "\nYou don't have a valid cluster active. You have two options:
* Use 'cluster:switch' to switch into one, or
* Run 'cluster:new' to create and switch into a new one.

"
      exit 1
    end
    unless Cluster::Base.skip_configtest?
      config.sane?
    else
      puts "Skipping cluster config sanity check!"
      true
    end
  end

  desc Cluster::RakeDocs.new('cluster:active').desc
  task active: [:configtest ] do
    remote_config = Cluster::RemoteConfig.new
    puts %Q|\nCurrently managing: "#{Cluster::Base.stack_config[:name]}" : #{remote_config.active_cluster_config_name}\n|
  end

  desc Cluster::RakeDocs.new('cluster:edit').desc
  task :edit do
    remote_config = Cluster::RemoteConfig.new
    system %Q|$EDITOR #{remote_config.active_cluster_config_name}|

    Rake::Task['cluster:configtest'].execute
    Rake::Task['cluster:config_sync_check'].execute
  end

  desc Cluster::RakeDocs.new('cluster:config_sync_check').desc
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
      print "Sync these changes and publish to AWS? (y or n): "
      answer = STDIN.gets.strip.chomp

      if ['y','Y'].include?(answer)
        remote_config.sync
        puts 'updating stack, app & layer attributes. . .'
        futures = ["Stack", "App", "Layers"].map do |cluster_class|
          Concurrent::Future.execute {
            eval("Cluster::#{cluster_class}.update")
          }
        end
        futures.map(&:value!)
      else
        puts "Quitting. Please resolve your config changes and try again."
        exit
      end
    end
  end

  desc Cluster::RakeDocs.new('cluster:console').desc
  task console: [:configtest, :config_sync_check, :production_failsafe] do
    Cluster::Console.run
  end

  desc Cluster::RakeDocs.new('cluster:reset').desc
  task reset: [:configtest, :config_sync_check, :production_failsafe, :reset_or_seed_check] do
    recipes = %W|oc-opsworks-recipes::stop-opencast
    oc-opsworks-recipes::reset-database
    oc-opsworks-recipes::remove-all-opencast-files
    oc-opsworks-recipes::create-opencast-directories
    oc-opsworks-recipes::remove-admin-indexes
    oc-opsworks-recipes::remove-engage-indexes|
    layers = ['Admin','Engage','Workers']
    custom_json='{"do_it":true}'

    Cluster::Deployment.execute_chef_recipes_on_layers(
      recipes: recipes,
      layers: layers,
      custom_json: custom_json
    )

    Rake::Task['opencast:start'].execute
  end

  desc Cluster::RakeDocs.new('cluster:create_seed_file').desc
  task create_seed_file: [:configtest, :config_sync_check, :production_failsafe, :reset_or_seed_check] do
    recipes = ['oc-opsworks-recipes::stop-opencast', 'oc-opsworks-recipes::create-cluster-seed-file']
    layers = ['Admin','Engage','Workers']
    custom_json ='{"do_it":true}'

    Cluster::Deployment.execute_chef_recipes_on_layers(
      recipes: recipes,
      layers: layers,
      custom_json: custom_json
    )

    Rake::Task['opencast:start'].execute
  end

  desc Cluster::RakeDocs.new('cluster:apply_seed_file').desc
  task apply_seed_file: [:configtest, :config_sync_check, :production_failsafe, :reset_or_seed_check] do

    chooser = Cluster::SeedFileChooser.new(
      seed_file: ENV['seed_file'].to_s.strip,
      bucket: Cluster::Base.cluster_seed_bucket_name
    )

    seed_file = if chooser.valid_seed_file?
                  chooser.seed_file
                else
                  chooser.choose
                end

    if seed_file == ''
      puts
      puts "*" * 40
      puts
      puts Cluster::RakeDocs.new('cluster:apply_seed_file').desc
      puts
      exit 1
    end

    recipes = %W|oc-opsworks-recipes::stop-opencast
    oc-opsworks-recipes::reset-database
    oc-opsworks-recipes::remove-all-opencast-files
    oc-opsworks-recipes::load-seed-data
    oc-opsworks-recipes::create-opencast-directories
    oc-opsworks-recipes::remove-admin-indexes
    oc-opsworks-recipes::remove-engage-indexes|
    layers = ['Admin','Engage','Workers']
    custom_json=%Q|{"do_it":true, "cluster_seed_file":"#{seed_file}"}|

    Cluster::Deployment.execute_chef_recipes_on_layers(
      recipes: recipes,
      layers: layers,
      custom_json: custom_json
    )

    Rake::Task['opencast:start'].execute
  end

  desc Cluster::RakeDocs.new('cluster:new').desc
  task :new do
    session = Cluster::ConfigCreationSession.new
    session.local_vs_opsworks
    session.get_project_tag
    session.choose_variant

    if ! session.ami_builder?
      session.analytics_node

      if session.zadara_variant?
        session.include_utility = true
      else
        session.utility_node
      end
    end

    session.get_cluster_name
    session.sns_email_subscription
    session.get_cookbook_source_type
    session.get_git_url
    session.get_git_revision
    session.compute_cidr_block_root
    session.compute_azs

    if session.zadara_variant?
      session.get_export_root
      session.get_nfs_server_host
    end

    config_file = Cluster::RemoteConfig.create(
      name: session.name,
      variant: session.variant,
      project_tag: session.project_tag,
      cidr_block_root: session.cidr_block_root,
      app_git_url: session.git_url,
      app_git_revision: session.git_revision,
      export_root: session.export_root,
      nfs_server_host: session.nfs_server_host,
      subnet_azs: session.subnet_azs.join(','),
      default_users: JSON.pretty_generate(session.compute_default_users),
      include_analytics: session.include_analytics,
      cookbook_source_type: session.cookbook_source_type,
      include_utility: session.include_utility,
      sns_email: session.sns_email
    )
    rc_file = Cluster::RcFileSwitcher.new(config_file: config_file)
    rc_file.write

    Cluster::RemoteConfig.new.sync
  end

  desc Cluster::RakeDocs.new('cluster:list').desc
  task :list do
    current_cluster_shortname = Cluster::Base.stack_shortname
    puts "Current cluster configurations:"
    puts
    Cluster::RemoteConfigs.all_with_human_names.each do |config|
      if current_cluster_shortname == config
        print "*"
      else
        print "-"
      end
      puts %Q| #{config}|
    end
    puts
    puts "* = active cluster"
  end

  desc Cluster::RakeDocs.new('cluster:switch').desc
  task :switch do
    session = Cluster::ClusterSwitcherSession.new

    if ! session.configs.any?
      puts 'No clusters yet.'
      exit
    end

    session.choose_cluster
    Cluster::RemoteConfig.new.sync
  end

end
