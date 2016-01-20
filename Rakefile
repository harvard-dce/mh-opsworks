require './lib/cluster'
Dir['./lib/tasks/*.rake'].each { |file| load file }

namespace :admin do
  namespace :cluster do
    desc Cluster::RakeDocs.new('admin:cluster:init').desc
    task init: ['cluster:configtest', 'cluster:config_sync_check'] do
      stack = Cluster::Stack.find_or_create

      if Cluster::Base.is_using_efs_storage?
        remote_config = Cluster::RemoteConfig.new
        remote_config.update_efs_server_hostname(Cluster::Filesystem.primary_efs_ip_address)
        remote_config.sync
        Cluster::Stack.update
      end

      puts %Q|Stack "#{stack.name}" initialized, id: #{stack.stack_id}|
      layers = Cluster::Layers.find_or_create

      Cluster::RDS.find_or_create
      Cluster::RegistersRDSInstance.register

      Cluster::Instances.find_or_create
      Cluster::App.find_or_create
      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" => #{layer.layer_id}|
        Cluster::Instances.find_in_layer(layer).each do |instance|
          puts %Q|	Instance: #{instance.hostname} => status: #{instance.status}, ec2_instance_id: #{instance.ec2_instance_id}|
        end
      end
      puts
      puts %Q|Initializing the cluster does not start instances. To start them, use "./bin/rake stack:instances:start"|
    end

    desc Cluster::RakeDocs.new('admin:cluster:delete').desc
    task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
      puts 'deleting app'
      Cluster::App.delete

      puts 'deleting sns topic and subscriptions'
      Cluster::SNS.delete

      puts 'deleting instances'
      Cluster::Instances.delete

      puts 'deleting RDS instance'
      Cluster::RDS.delete

      puts 'deleting stack'
      Cluster::Stack.delete

      puts 'deleting instance profile'
      Cluster::InstanceProfile.delete

      puts 'deleting service role'
      Cluster::ServiceRole.delete

      puts 'deleting VPC'
      Cluster::VPC.delete

      puts 'deleting S3 distribution bucket and assets'
      Cluster::S3DistributionBucket.delete

      puts 'deleting configuration files'
      Cluster::RemoteConfig.new.delete
    end
  end

  namespace :users do
    desc Cluster::RakeDocs.new('admin:users:list').desc
    task list: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::IAMUser.all.each do |user|
        puts %Q|#{user.user_name} => #{user.arn}|
      end
    end
  end

  desc Cluster::RakeDocs.new('admin:republish_maven_cache').desc
  task republish_maven_cache: ['cluster:configtest', 'cluster:config_sync_check'] do
    asset_bucket_name = Cluster::Base.shared_asset_bucket_name

    a_public_host = Cluster::Instances.online.find do |instance|
      (instance.public_dns != nil) && instance.hostname.match(/admin/)
    end

    system %Q|ssh -C #{a_public_host.public_dns} 'sudo bash -c "cd /root && tar cvfz - .m2/"' > maven_cache.tgz|

    puts %Q|Uploading maven_cache.tgz to #{asset_bucket_name}|
    Cluster::Assets.publish_support_asset_to(
      bucket: asset_bucket_name,
      file_name: 'maven_cache.tgz',
      permissions: 'public'
    )
    puts 'done.'

    File.unlink('maven_cache.tgz')
  end
end

task :default do
  Rake.application.tasks.each do |task|
    puts "./bin/rake #{task.name}"
  end
  puts
  puts 'Run "./bin/rake -T" for full task output'
end

