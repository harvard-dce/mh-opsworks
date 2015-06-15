namespace :stack do
  desc 'list stacks'
  task list: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Stack.all.each do |stack|
      puts %Q|#{stack.name} => #{stack.vpc_id}|
    end
  end

  desc 'delete stack. You must remove all instances and apps first'
  task delete: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Stack.with_existing_stack do |stack|
      Cluster::Stack.delete
    end
  end

  desc 'Initialize a stack within a vpc'
  task init: ['cluster:configtest', 'cluster:config_sync_check'] do
    stack = Cluster::Stack.find_or_create
    puts %Q|Stack "#{stack.name}" initialized, id: #{stack.stack_id}|
    app = Cluster::App.find_or_create
    puts "App: #{app.name} created"
  end

  namespace :users do
    desc 'list users in the configured stack'
    task list: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::User.all.each do |permission|
        puts %Q|#{permission.iam_user_arn} => #{permission.level}|
      end
    end

    desc 'init the users and rights in the configured cluster'
    task init: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        Cluster::User.reset_stack_user_permissions_for(
          stack.stack_id
        )
      end
    end
  end

  namespace :instances do
    desc 'init instances in each layer'
    task init: ['cluster:configtest', 'cluster:config_sync_check', 'stack:layers:init'] do
      Cluster::Instances.find_or_create
    end

    desc 'ssh connection string'
    task ssh_to: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        hostname = ENV['hostname'].to_s.strip

        a_public_host = Cluster::Instances.online.find do |instance|
          instance.public_dns != nil
        end

        if hostname != ''
          instance = Cluster::Instances.find_by_hostname(hostname)
          if instance == nil
            puts "#{hostname} does not exist"
            exit 1
          end

          if ! ['online', 'running_setup'].include?(instance.status)
            puts "#{hostname} is not online or ssh'able. You might try with the default stack key."
          elsif instance.public_dns == nil
            puts "ssh -A -t #{a_public_host.public_dns} ssh -A #{hostname}"
          else
            puts "ssh -A #{instance.public_dns}"
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
          puts
          puts './bin/rake stack:instances:ssh_to hostname=<an instance name>'
          puts
          puts 'You can also connect directly to a machine by executing the output'
          puts 'of this task, thusly:'
          puts
          puts '$(./bin/rake stack:instances:ssh_to hostname=<an instance name>)'
        end
      end
    end

    desc 'list instances in each layer'
    task list: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        layers = Cluster::Layers.find_or_create
        layers.each do |layer|
          puts %Q|Layer: "#{layer.name}" => #{layer.layer_id}, #{layer.shortname}|
            Cluster::Instances.find_in_layer(layer).each do |instance|
            puts %Q|	Instance: #{instance.hostname} => status: #{instance.status}, ec2_instance_id: #{instance.ec2_instance_id}|
          end
        end
      end
    end

    desc 'stop and delete all instances in the stack'
    task delete: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Instances.delete
    end

    desc 'stop all instances in the configured stack'
    task stop: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.stop_all
    end

    desc 'start all instances in the configured stack'
    task start: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.start_all
    end
  end

  namespace :layers do
    desc 'list layers in configured stack'
    task list: ['cluster:configtest', 'cluster:config_sync_check'] do
      # find the layers from the stack object to ensure we're seeing
      # what's actually there.
      Cluster::Stack.with_existing_stack do |stack|
        stack.layers.each do |layer|
          puts layer.name
        end
      end
    end

    desc 'init layers'
    task init: ['cluster:configtest', 'cluster:config_sync_check', 'stack:init'] do
      layers = Cluster::Layers.find_or_create
      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" ready to serve!|
      end
    end
  end

  namespace :commands do
    desc 'run custom chef recipes'
    task execute_recipes: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        layers = ENV['layers'].to_s.strip.split(/,[\s]?/)
        recipes = ENV['recipes'].to_s.strip.split(/,[\s]?/)

        if recipes.none?
          puts %Q|Please indicate the recipes you'd like to run.|
          puts %Q|If you don't specify any layers, the recipes will be run on all layers.|
          puts
          puts './bin/rake stack:commands:execute_recipes recipes="recipe1,recipe1" layers="Full Name,Full Name2"'
        else
          Cluster::Deployment.execute_chef_recipes_on_layers(
            recipes: recipes,
            layers: layers
          )
        end
      end
    end

    desc 'update all chef recipes'
    task update_chef_recipes: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Deployment.update_chef_recipes

      Cluster::Stack.with_existing_stack do |stack|
        puts "Updating all recipes in: "
        puts stack.custom_cookbooks_source.url
        puts "Revision or branch: #{ stack.custom_cookbooks_source.revision }"
      end
    end

    desc 'install updated OS packages'
    task update_packages: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Deployment.update_dependencies
      puts 'Updating OS packages'
    end
  end
end
