module Cluster
  class Deployment < Base
    def self.deploy_app
      stack = Stack.find_or_create
      app = App.find_or_create
      custom_json = deployment_config[:custom_json]
      opsworks_client.create_deployment(
        stack_id: stack.stack_id,
        app_id: app.app_id,
        instance_ids: instance_ids,
        command: {
          name: 'deploy'
        },
        custom_json: json_encode(custom_json)
      )
    end

    private

    def self.instance_ids
      instances = []
      deployment_config[:to_layers].each do |name|
        layer = Layer.find_existing_by_name(name)
        instances += Cluster::Instances.find_in_layer(layer)
      end
      instances.map(&:instance_id)
    end
  end
end
