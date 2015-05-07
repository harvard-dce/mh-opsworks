module Cluster
  class Instances < Base
    # This returns a list of opsworks instance structs (rather than actual
    # API-connected classes).  This is because an instance in the OpsWorks
    # context is a higher-level abstraction than just a EC2 image proper and
    # there isn't a single client API that makes sense for them.
    def self.find_in_layer(layer)
      opsworks_client.describe_instances(layer_id: layer.layer_id).instances
    end

    def self.find_by_hostname(hostname)
      find_existing.find do |instance|
        instance.hostname == hostname
      end
    end

    # Stops and then deletes all instances.
    def self.delete
      instances = []
      stack = Cluster::Stack.find_existing
      if stack
        Cluster::Stack.stop_all
        opsworks_client.describe_instances(stack_id: stack.stack_id).inject([]){ |memo, page| memo + page.instances }.each do |instance|
          opsworks_instance = Cluster::Instance.new(instance.instance_id)
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
        instances_config = instances_config_in_layer(layer.shortname)
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

    def self.find_existing
      stack = Stack.find_existing
      opsworks_client.describe_instances(stack_id: stack.stack_id).inject([]){ |memo, page| memo + page.instances }
    end

    def self.online
      find_existing.reject{|instance| instance.status != 'online'}
    end

    private

    def self.get_instances_in(layer)
      opsworks_client.describe_instances(layer_id: layer.layer_id).inject([]){ |memo, page| memo + page.instances }
    end
  end
end
