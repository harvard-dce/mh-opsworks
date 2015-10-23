module Cluster
  class Deployment < Base
    include Cluster::Waiters

    def self.all
      stack = Cluster::Stack.with_existing_stack
      opsworks_client.describe_deployments(
        stack_id: stack.stack_id
      ).inject([]){ |memo, page| memo + page.deployments }
    end

    def self.rollback_app
      deploy_app(deploy_action: :rollback)
    end

    def self.redeploy_app
      deploy_app(deploy_action: :force_deploy)
    end

    def self.redeploy_app_with_unit_tests
      deploy_app(deploy_action: :force_deploy, skip_java_unit_tests: false)
    end

    def self.deploy_app(custom_json_overrides = {})
      stack = Cluster::Stack.with_existing_stack
      app = App.find_or_create
      custom_json = deployment_config[:custom_json].merge(custom_json_overrides)

      if app
        deployment = opsworks_client.create_deployment(
          stack_id: stack.stack_id,
          app_id: app.app_id,
          instance_ids: deployable_instance_ids_in_layers(deployment_config[:to_layers]),
          command: {
            name: 'deploy'
          },
          custom_json: json_encode(custom_json)
        )
        wait_until_deployment_completed(deployment.deployment_id)
      end
    end

    def self.execute_chef_recipes_on_instances(recipes: [], hostnames: [], custom_json: '')
      raise NoRecipesToRun if recipes.none?

      run_command_on_instances(
        command: 'execute_recipes',
        args: { recipes: recipes },
        hostnames: hostnames,
        custom_json: custom_json
      )
    end

    def self.execute_chef_recipes_on_layers(recipes: [], layers: [], custom_json: '')
      raise NoRecipesToRun if recipes.none?

      run_command_on_layers(
        command: 'execute_recipes',
        args: { recipes: recipes },
        layers: layers,
        custom_json: custom_json
      )
    end

    def self.update_dependencies
      run_command_on_layers(command: 'dependencies')
    end

    def self.update_chef_recipes
      run_command_on_layers(command: 'update_custom_cookbooks')
    end

    private

    def self.run_command_on_instances(hostnames: [], command: nil, args: {}, custom_json: '')
      Cluster::Stack.with_existing_stack do |stack|
        instance_ids = Cluster::Instances.online.find_all do |instance|
          hostnames.include?(instance.hostname)
        end.map(&:instance_id)

        run_on_instance_ids(
          instance_ids: instance_ids,
          stack: stack,
          command: command,
          args: args,
          custom_json: custom_json
        )
      end
    end

    def self.run_command_on_layers(layers: [], command: nil, args: {}, custom_json: '')
      Cluster::Stack.with_existing_stack do |stack|
        instance_ids = []
        if layers.any?
          instance_ids = deployable_instance_ids_in_layers(layers)
        else
          instance_ids = Cluster::Instances.online.map(&:instance_id)
        end
        run_on_instance_ids(
          instance_ids: instance_ids,
          stack: stack,
          command: command,
          args: args,
          custom_json: custom_json
        )
      end
    end

    def self.run_on_instance_ids(
      instance_ids: [], stack: nil, command: nil, args: {}, custom_json: ''
    )
      if instance_ids.any?
        deployment = opsworks_client.create_deployment(
          stack_id: stack.stack_id,
          instance_ids: instance_ids,
          command: {
            name: command,
            args: args
          },
          custom_json: custom_json
        )
        wait_until_deployment_completed(deployment.deployment_id)
      end
    end

    def self.deployable_instance_ids_in_layers(layers)
      stack = Cluster::Stack.with_existing_stack
      instances = []
      online_instances = Cluster::Instances.online

      layers.each do |name|
        layer = Layer.find_existing_by_name(stack, name)
        instances += online_instances.find_all{|instance| instance.layer_ids.include?(layer.layer_id) }
      end
      instances.map(&:instance_id)
    end
  end
end
