require './lib/cluster'
Dir['./lib/tasks/*.rake'].each { |file| load file }

namespace :admin do
  namespace :cluster do
    desc 'Initialize a matterhorn cluster using the policies in your defined cluster_config.json'
    task init: ['cluster:configtest'] do
      stack = Cluster::Stack.find_or_create
      puts %Q|Stack "#{stack.name}" initialized, id: #{stack.stack_id}|
      layers = Cluster::Layers.find_or_create
      Cluster::Instances.find_or_create
      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" => #{layer.layer_id}|
        Cluster::Instances.find_in_layer(layer).each do |instance|
          puts %Q|	Instance: #{instance.hostname} => status: #{instance.status}, ec2_instance_id: #{instance.ec2_instance_id}|
        end
      end
      puts
      puts %Q|Initializing the cluster does not start instances. To start them, use "rake stack:instances:start"|
    end

    desc 'Delete a matterhorn cluster using the policies defined in your cluster_config.json'
    task delete: ['cluster:configtest'] do
      puts 'deleting instances'
      Cluster::Instances.delete
      puts 'deleting stack'
      Cluster::Stack.delete
      puts 'deleting instance profile'
      Cluster::InstanceProfile.delete
      puts 'deleting service role'
      Cluster::ServiceRole.delete
      puts 'deleting VPC'
      Cluster::VPC.delete
    end
  end

  namespace :users do
    desc 'list all IAM users'
    task list: ['cluster:configtest'] do
      Cluster::IAMUser.all.each do |user|
        puts %Q|#{user.user_name} => #{user.arn}|
      end
    end
  end
end
