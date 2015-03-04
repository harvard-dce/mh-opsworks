module Cluster
  class Instance < Base
    def self.find_or_create_in_layer(layer, instances_config)
      instance_params = {
        stack_id: layer.stack_id,
        layer_ids: [layer.layer_id],
        root_device_type: instances_config.fetch(:root_device_type, 'instance-store'),
        instance_type: instances_config.fetch(:instance_type, 't2.micro')
      }
      opsworks_client.create_instance(instance_params)
    end
  end
end
