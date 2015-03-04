module Cluster
  class Instances < Base
    # This returns a list of opsworks instance structs (rather than actual
    # API-connected classes).  This is because an instance in the OpsWorks
    # context is a higher-level abstraction than just a EC2 image proper and
    # there isn't a single client API that makes sense for them.
    def self.find_in_layer(layer)
      get_instances_in(layer)
    end

    # Iterate over configured layers and creates the configured instances
    def self.find_or_create
      instances = []
      Layers.find_or_create.each do |layer|
        instances_config = instances_in_layer(layer.name)
        syncer = InstanceSyncer.new(
          layer: layer,
          instances_config: instances_config
        )
        removed_instances = syncer.remove_excess_instances
        instances += (syncer.create_new_instances || [])
      end
      instances
    end

    private

    def self.get_instances_in(layer)
      opsworks_client.describe_instances(layer_id: layer.layer_id).instances
    end
  end
end
