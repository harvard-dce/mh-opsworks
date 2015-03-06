require './lib/cluster'
Dir['./lib/tasks/*.rake'].each { |file| load file }

namespace :admin do
  namespace :cluster do
    desc 'Initialize a matterhorn cluster using the policies in your defined cluster_config.json'
    task init: ['cluster:configtest', 'stack:init', 'stack:layers:init', 'stack:instances:init', 'stack:instances:list'] do
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
