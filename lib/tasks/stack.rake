namespace :stack do
  desc Cluster::RakeDocs.new('stack:list').desc
  task list: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Stack.all.each do |stack|
      puts %Q|#{stack.stack_id}	#{stack.vpc_id}	#{stack.name}|
    end
  end

  desc Cluster::RakeDocs.new('stack:delete').desc
  task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::Stack.with_existing_stack do |stack|
      Cluster::Stack.delete
    end
  end

  task update: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::Stack.update
    Cluster::App.update
  end

  desc Cluster::RakeDocs.new('stack:init').desc
  task init: ['cluster:configtest', 'cluster:config_sync_check'] do
    stack = Cluster::Stack.find_or_create
    puts %Q|Stack "#{stack.name}" initialized, id: #{stack.stack_id}|
    app = Cluster::App.find_or_create
    puts "App: #{app.name} created"
  end

  namespace :users do
    desc Cluster::RakeDocs.new('stack:users:list').desc
    task list: ['cluster:configtest', 'cluster:config_sync_check'] do
      output = []
      Cluster::User.all.each do |permission|
        output << %Q|#{permission.level}	#{permission.iam_user_arn}|
      end
      puts output.sort
    end

    desc Cluster::RakeDocs.new('stack:users:init').desc
    task init: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        Cluster::User.reset_stack_user_permissions_for(
          stack.stack_id
        )
      end
    end
  end

  namespace :instances do
    desc Cluster::RakeDocs.new('stack:instances:init').desc
    task init: ['cluster:configtest', 'cluster:config_sync_check', 'stack:layers:init'] do
      Cluster::Instances.find_or_create
    end

    desc Cluster::RakeDocs.new('stack:instances:ssh_to').desc
    task ssh_to: ['cluster:configtest'] do
      Cluster::Stack.with_existing_stack do |stack|
        ssh_user = ENV.fetch('ssh_user', %Q|#{ENV['USER']}|) + '@'
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
            puts "ssh -A -t #{ssh_user}#{a_public_host.public_dns} ssh -A -t #{ssh_user}#{hostname}"
          else
            puts "ssh -A -t #{ssh_user}#{instance.public_dns}"
          end
        else
          layers = Cluster::Layers.find_or_create
          layers.each do |layer|
            puts %Q|Instances running in "#{layer.name}":|
            Cluster::Instances.find_in_layer(layer).each do |instance|
              puts %Q|	#{instance.hostname}|
            end
          end
          puts
          puts "*" * 40
          puts
          puts Cluster::RakeDocs.new('stack:instances:ssh_to').desc
          puts
        end
      end
    end

    desc Cluster::RakeDocs.new('stack:instances:list').desc
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

    desc Cluster::RakeDocs.new('stack:instances:delete').desc
    task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
      Cluster::Instances.delete
    end

    desc Cluster::RakeDocs.new('stack:instances:stop').desc
    task stop: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
      Cluster::Stack.stop_all
    end

    desc Cluster::RakeDocs.new('stack:instances:start').desc
    task start: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.start_all
    end
  end

  namespace :layers do
    desc Cluster::RakeDocs.new('stack:layers:list').desc
    task list: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        stack.layers.each do |layer|
          puts layer.name
        end
      end
    end

    desc Cluster::RakeDocs.new('stack:layers:init').desc
    task init: ['cluster:configtest', 'cluster:config_sync_check', 'stack:init'] do
      layers = Cluster::Layers.update
      layers.each do |layer|
        puts %Q|Layer: "#{layer.name}" ready to serve!|
      end
    end
  end

  namespace :commands do
    desc Cluster::RakeDocs.new('stack:commands:execute_recipes_on_layers').desc
    task execute_recipes_on_layers: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        layers = ENV['layers'].to_s.strip.split(/,[\s]?/)
        recipes = ENV['recipes'].to_s.strip.split(/,[\s]?/)
        custom_json = ENV['custom_json'].to_s.strip

        if recipes.none?
          puts
          puts "*" * 40
          puts
          puts Cluster::RakeDocs.new('stack:commands:execute_recipes_on_layers').desc
          puts
        else
          Cluster::Deployment.execute_chef_recipes_on_layers(
            recipes: recipes,
            layers: layers,
            custom_json: custom_json
          )
        end
      end
    end

    desc Cluster::RakeDocs.new('stack:commands:execute_recipes_on_instances').desc
    task execute_recipes_on_instances: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Stack.with_existing_stack do |stack|
        hostnames = ENV['hostnames'].to_s.strip.split(/,[\s]?/)
        recipes = ENV['recipes'].to_s.strip.split(/,[\s]?/)
        custom_json = ENV['custom_json'].to_s.strip

        if recipes.none? || hostnames.none?
          puts
          puts "*" * 40
          puts
          puts Cluster::RakeDocs.new('stack:commands:execute_recipes_on_instances').desc
          puts
        else
          Cluster::Deployment.execute_chef_recipes_on_instances(
            recipes: recipes,
            hostnames: hostnames,
            custom_json: custom_json
          )
        end
      end
    end

    desc Cluster::RakeDocs.new('stack:commands:update_chef_recipes').desc
    task update_chef_recipes: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Deployment.update_chef_recipes

      Cluster::Stack.with_existing_stack do |stack|
        puts "Updating all recipes in: "
        puts stack.custom_cookbooks_source.url
        puts "Revision or branch: #{ stack.custom_cookbooks_source.revision }"
      end
    end

    desc Cluster::RakeDocs.new('stack:commands:update_packages').desc
    task update_packages: ['cluster:configtest', 'cluster:config_sync_check'] do
      Cluster::Deployment.update_dependencies
      puts 'Updating OS packages'
    end
  end
end
