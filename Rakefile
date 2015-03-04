require './lib/cluster'
Dir['./lib/tasks/*.rake'].each { |file| load file }

namespace :admin do
  namespace :cluster do
    desc 'Initialize a matterhorn cluster using the policies in your defined cluster_config.json'
    task init: ['cluster:configtest', 'stack:init', 'stack:layers:init'] do
    end

    desc 'Delete a matterhorn cluster using the policies defined in your cluster_config.json'
    task delete: ['cluster:configtest'] do
      Cluster::Stack.delete
      Cluster::InstanceProfile.delete
      Cluster::ServiceRole.delete
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
