module Cluster
  class Deployment < Base
    def self.all
      stack = Cluster::Stack.with_existing_stack
      opsworks_client.describe_deployments(stack_id: stack.stack_id).deployments
    end

    def self.deploy_app
      stack = Cluster::Stack.with_existing_stack
      app = App.find_or_create
      custom_json = deployment_config[:custom_json]

      app && opsworks_client.create_deployment(
        stack_id: stack.stack_id,
        app_id: app.app_id,
        instance_ids: deployable_instance_ids_in_layers(deployment_config[:to_layers]),
        command: {
          name: 'deploy'
        },
        custom_json: json_encode(custom_json)
      )
    end

    def self.run_command_on_instances(layers: [], command: nil, args: {})
      Cluster::Stack.with_existing_stack do |stack|
        instance_ids = []
        if layers.any?
          instance_ids = deployable_instance_ids_in_layers(layers)
        else
          instance_ids = Cluster::Instances.online.map(&:instance_id)
        end

        if instance_ids.any?
          opsworks_client.create_deployment(
            stack_id: stack.stack_id,
            instance_ids: instance_ids,
            command: {
              name: command,
              args: args
            }
          )
        else
          raise Cluster::NoInstancesOnline
        end
      end
    end

    def self.execute_chef_recipes_on_layers(recipes: [], layers: [])
      raise NoRecipesToRun if recipes.none?

      run_command_on_instances(
        command: 'execute_recipes',
        args: { recipes: recipes },
        layers: layers
      )
    end

    def self.update_dependencies
      run_command_on_instances(command: 'update_dependencies')
    end

    def self.update_chef_recipes
      run_command_on_instances(command: 'update_custom_cookbooks')
    end

    private

    def self.deployable_instance_ids_in_layers(layers)
      instances = []
      online_instances = Cluster::Instances.online

      layers.each do |name|
        layer = Layer.find_existing_by_name(name)
        instances += online_instances.find_all{|instance| instance.layer_ids.include?(layer.layer_id) }
      end
      instances.map(&:instance_id)
    end
  end
end
