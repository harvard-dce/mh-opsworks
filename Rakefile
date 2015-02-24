require './lib/cluster'

namespace :admin do
  namespace :cluster do
    desc 'Initialize a matterhorn cluster using the policies in your defined cluster_config.json'
    task init: ['cluster:configtest', 'stack:init'] do

    end
  end

  namespace :instance_profiles do
    desc 'list instance profiles'
    task list: ['cluster:configtest'] do
      Cluster::InstanceProfile.all.each do |instance_profile|
        puts %Q|#{instance_profile.instance_profile_name} => roles: #{instance_profile.roles.map{|r| r.role_name}.join(',')}|
      end
    end
  end

  namespace :service_roles do
    desc 'initialize service roles'
    task init: ['cluster:configtest'] do
      Cluster::ServiceRole.find_or_create
    end

    desc 'Show service roles'
    task list: ['cluster:configtest'] do
      Cluster::ServiceRole.all.each do |role|
        puts role.inspect
      end
    end
  end

  namespace :users do
    desc 'list users. Requires an elevated privilege account'
    task list: ['cluster:configtest'] do
      Cluster::User.all.each do |user|
        puts user.inspect
      end
    end

    desc 'init the users and rights for this cluster'
    task init: ['cluster:configtest'] do
      Cluster::User.create_developer_group
    end
  end
end

namespace :stack do
  desc 'list stacks'
  task list: ['cluster:configtest'] do
    Cluster::Stack.all.each do |stack|
      puts %Q|#{stack.name} => #{stack.vpc_id}|
    end
  end

  desc 'Initialize a stack within a vpc'
  task init: ['cluster:configtest'] do
    Cluster::Stack.find_or_create
  end
end

namespace :vpc do
  desc 'list vpcs'
  task list: ['cluster:configtest'] do
    Cluster::VPC.all.each do |vpc|
      puts %Q|#{vpc.vpc_id} => #{vpc.cidr_block}, #{vpc.tags}|
    end
  end

  desc 'Initialize a VPC according to your cluster config'
  task init: ['cluster:configtest'] do
    Cluster::VPC.find_or_create
  end
end

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
