require './lib/cluster'
require 'colorize'
Dir['./lib/tasks/*.rake'].each { |file| load file }

namespace :admin do
  namespace :cluster do
    desc Cluster::RakeDocs.new('admin:cluster:init').desc
    task init: ['cluster:configtest', 'cluster:config_sync_check'] do

      vpc = Cluster::VPC.find_or_create

      Cluster::SubscribesSnsEndpoints.subscribe

      rds_create = Concurrent::Future.execute do
        Cluster::RDS.find_or_create
      end

      stack = Cluster::Stack.find_or_create

      puts %Q|Stack "#{stack.name}" initialized, id: #{stack.stack_id}|
      layers = Cluster::Layers.find_or_create

      Cluster::Instances.find_or_create
      Cluster::S3DistributionBucket.find_or_create(Cluster::Base.distribution_bucket_name)
      Cluster::S3ArchiveBucket.find_or_create(Cluster::Base.s3_file_archive_bucket_name)

      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" => #{layer.layer_id}|
        Cluster::Instances.find_in_layer(layer).each do |instance|
          puts %Q|	Instance: #{instance.hostname} => status: #{instance.status}, ec2_instance_id: #{instance.ec2_instance_id}|
        end
      end

      begin
        rds_create.value!
      rescue => e
        puts "Something went wrong creating rds cluster: #{rds_create.reason}"
        puts e.backtrace
      end

      Cluster::RegistersRDSInstance.register
      Cluster::App.find_or_create

      # update the stack config so it gets the RDS cluster endpoint
      Cluster::Stack.update

      puts
      puts %Q|Initializing the cluster does not start instances. To start them, use "./bin/rake stack:instances:start"|
      puts
      puts %Q|Initializing the cluster starts your RDS cluster! Please run 'rds:cluster' if you're not starting the opsworks cluster right away!|.yellow
    end

    desc Cluster::RakeDocs.new('admin:cluster:delete').desc
    task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
      puts 'deleting app'
      Cluster::App.delete

      puts 'deleting sns topic and subscriptions'
      Cluster::SNS.delete

      rds_delete = Concurrent::Future.execute do
        puts 'deleting RDS cluster'

        # RDS Clusters won't delete when in a stopped state! :(
        existing_rds = Cluster::RDS.find_existing
        if existing_rds
          Cluster::RDS.start
        end

        Cluster::RDS.delete
      end

      puts 'deleting instances'
      Cluster::Instances.delete

      puts 'deleting stack'
      Cluster::Stack.delete

      puts 'deleting instance profile'
      Cluster::InstanceProfile.delete

      puts 'deleting service role'
      Cluster::ServiceRole.delete

      puts 'deleting S3 distribution and file archive buckets and assets'
      Cluster::S3DistributionBucket.delete(Cluster::Base.distribution_bucket_name)
      Cluster::S3ArchiveBucket.delete(Cluster::Base.s3_file_archive_bucket_name)

      puts 'deleting analytics buckets'
      Cluster::S3AnalyticsBuckets.delete

      puts 'deleting cloudwatch log groups'
      Cluster::CWLogs.delete

      puts 'deleting SQS queues'
      Cluster::SQS.delete_queue(Cluster::Base.useractions_queue_name)

      begin
        rds_delete.value!
      rescue => e
        puts "Something went wrong deleting the rds cluster: #{rds_delete.reason}"
        # reraise the exception to stop execution of the delete
        # (not sure this is better than continuing, but seems less likely to result
        # in orphaned rds resources if the vpc and cluster config hang around too)
        raise
      end

      puts 'deleting VPC'
      Cluster::VPC.delete

      puts 'deleting configuration files'
      Cluster::RemoteConfig.new.delete
    end

    desc Cluster::RakeDocs.new('admin:cluster:tag').desc
    task tag: ['cluster:configtest', 'cluster:config_sync_check'] do
      puts 'tagging instances and volumes'
      Cluster::Instances.create_custom_tags

      puts 'tagging vpc'
      Cluster::VPC.create_custom_tags

      puts 'tagging rds instance'
      Cluster::RDS.create_custom_tags

      puts 'tagging s3 buckets'
      Cluster::S3Bucket.create_custom_tags(Cluster::Base.distribution_bucket_name)
      Cluster::S3Bucket.create_custom_tags(Cluster::Base.s3_file_archive_bucket_name)
    end

    desc Cluster::RakeDocs.new('admin:cluster:subscribe').desc
    task subscribe: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::SubscribesSnsEndpoints.subscribe
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

    system %Q|ssh -C #{a_public_host.public_dns} 'sudo bash -c "cd /root && tar cvfz - .m2/"' > oc_maven_cache.tgz|

    puts %Q|Uploading oc_maven_cache.tgz to #{asset_bucket_name}|
    Cluster::Assets.publish_support_asset_to(
      bucket: asset_bucket_name,
      file_name: 'oc_maven_cache.tgz',
      permissions: 'public'
    )
    puts 'done.'

    File.unlink('oc_maven_cache.tgz')
  end

end

task :default do
  Rake.application.tasks.each do |task|
    puts "./bin/rake #{task.name}"
  end
  puts
  puts 'Run "./bin/rake -T" for full task output'
end

