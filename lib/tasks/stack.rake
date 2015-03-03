namespace :stack do
  desc 'list stacks'
  task list: ['cluster:configtest'] do
    Cluster::Stack.all.each do |stack|
      puts %Q|#{stack.name} => #{stack.vpc_id}|
    end
  end

  desc 'Initialize a stack within a vpc'
  task init: ['cluster:configtest'] do
    stack = Cluster::Stack.find_or_create
    puts %Q|Stack "#{stack.name}" initialized, id: #{stack.stack_id}|
  end

  namespace :users do
    desc 'list users in the configured stack'
    task list: ['cluster:configtest'] do
      Cluster::User.all.each do |permission|
        puts %Q|#{user.iam_user_arn} => #{user.level}|
      end
    end

    desc 'init the users and rights in the configured cluster'
    task init: ['cluster:configtest'] do
      Cluster::User.reset_stack_user_permissions_for(
        Cluster::Stack.find_or_create.stack_id
      )
    end
  end

  namespace :layers do
    desc 'list layers in configured stack'
    task list: ['cluster:configtest'] do
      Cluster::Stack.find_or_create.layers.each do |layer|
        puts layer.name
      end
    end

    desc 'init layers'
    task init: ['cluster:configtest', 'stack:init'] do
      Cluster::Layers.as_configured do |layer|
        layer.find_or_create
      end
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
    desc 'list service roles'
    task list: ['cluster:configtest'] do
      Cluster::ServiceRole.all.each do |role|
        puts role.inspect
      end
    end
  end
end
