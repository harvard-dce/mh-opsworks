module Cluster
  class Instances < Base
    # This returns a list of opsworks instance structs (rather than actual
    # API-connected classes).  This is because an instance in the OpsWorks
    # context is a higher-level abstraction than just a EC2 image proper and
    # there isn't a single client API that makes sense for them.
    def self.find_in_layer(layer)
      opsworks_client.describe_instances(layer_id: layer.layer_id).instances
    end

    # Returns a list of instances that were deleted.
    def self.delete
      instances = []
      vpc = Cluster::VPC.find_existing
      stack = Cluster::Stack.find_existing_in(vpc)
      if vpc && stack
        opsworks_client.describe_instances(stack_id: stack.stack_id).instances.each do |instance|
          opsworks_instance = Cluster::Instance.new(instance.instance_id)
          opsworks_instance.stop
          opsworks_instance.wait_for_instance_to_stop
          opsworks_instance.delete

          instances << instance
        end
      end
      instances
    end

    # Iterate over configured layers and creates the configured instances
    def self.find_or_create
      instances = []
      Layers.find_or_create.each do |layer|
        instances_config = instances_config_in_layer(layer.name)
        syncer = InstanceSyncer.new(
          layer: layer,
          instances_config: instances_config
        )
        removed_instances = syncer.remove_excess_instances
        syncer.create_new_instances
        instances += get_instances_in(layer)
      end
      instances
    end

    private

    def self.get_instances_in(layer)
      opsworks_client.describe_instances(layer_id: layer.layer_id).instances
    end
  end
end
