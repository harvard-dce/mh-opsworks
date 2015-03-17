module Cluster
  class Deployment < Base
    def self.all

    end

    def self.deploy_app
      stack = Cluster::Stack.with_existing_stack
      app = App.find_or_create
      custom_json = deployment_config[:custom_json]
      app && opsworks_client.create_deployment(
        stack_id: stack.stack_id,
        app_id: app.app_id,
        instance_ids: deployable_instance_ids,
        command: {
          name: 'deploy'
        },
        custom_json: json_encode(custom_json)
      )
    end

    private

    def self.deployable_instance_ids
      instances = []
      online_instances = Cluster::Instances.online

      deployment_config[:to_layers].each do |name|
        layer = Layer.find_existing_by_name(name)
        instances += online_instances.find_all{|instance| instance.layer_ids.include?(layer.layer_id) }
      end
      instances.map(&:instance_id)
    end
  end
end
