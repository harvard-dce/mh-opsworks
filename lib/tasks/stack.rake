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

  namespace :instances do
    desc 'init instances in each layer'
    task init: ['cluster:configtest', 'stack:layers:init'] do
      Cluster::Instances.find_or_create
    end

    desc 'ssh connection string'
    task ssh_to: ['cluster:configtest'] do
      hostname = ENV['hostname'].to_s.strip

      if hostname != ''
        instance = Cluster::Instances.find_by_hostname(hostname)
        if instance == nil
          puts "#{hostname} does not exist"
          exit 1
        end

        if instance.status != 'online'
          puts "#{hostname} is not online"
        elsif instance.public_dns == nil
          puts "To be implemented - ssh'ing to private instances"
        else
          puts "ssh #{instance.public_dns}"
        end
      else
        layers = Cluster::Layers.find_or_create
        layers.each do |layer|
          puts %Q|Instances running in "#{layer.name}":|
          Cluster::Instances.find_in_layer(layer).each do |instance|
            puts %Q|	#{instance.hostname}|
          end
        end
        puts 'Please specify an instance name to connect to, thusly:'
        puts 'rake stack:instances:ssh_to hostname=<an instance name>'
      end
    end

    desc 'list instances in each layer'
    task list: ['cluster:configtest', 'stack:layers:init'] do
      layers = Cluster::Layers.find_or_create
      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" => #{layer.layer_id}|
          Cluster::Instances.find_in_layer(layer).each do |instance|
          puts %Q|	Instance: #{instance.hostname} => status: #{instance.status}, ec2_instance_id: #{instance.ec2_instance_id}|
        end
      end
    end

    desc 'stop all instances in the configured stack'
    task stop: ['cluster:configtest', 'stack:layers:init', 'stack:instances:init'] do
      Cluster::Instances.stop_all
    end

    desc 'start all instances in the configured stack'
    task start: ['cluster:configtest', 'stack:layers:init', 'stack:instances:init'] do
      Cluster::Instances.start_all
    end
  end

  namespace :layers do
    desc 'list layers in configured stack'
    task list: ['cluster:configtest'] do
      # find the layers from the stack object to ensure we're seeing
      # what's actually there.
      Cluster::Stack.find_or_create.layers.each do |layer|
        puts layer.name
      end
    end

    desc 'init layers'
    task init: ['cluster:configtest', 'stack:init'] do
      layers = Cluster::Layers.find_or_create
      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" ready to serve!|
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
