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

    def self.find_manageable_instances_by_layer_shortname(shortnames=[])
      layer_ids = Cluster::Layers.find_by_shortnames(shortnames).map(&:layer_id)
      Cluster::Instances.find_existing_always_on_instances.find_all do |instance|
        layer_ids.include?(instance.layer_ids.first)
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
        create_instances_for(layer, instances_config, 'always on')
        if instances_config.has_key?(:scaling)
          create_instances_for(layer, instances_config, 'load based')
        end
        instances += get_instances_in(layer)
      end
      instances
    end

    def self.find_existing
      instances = []
      stack = Stack.find_existing
      if stack
        instances = opsworks_client.describe_instances(stack_id: stack.stack_id).inject([]){ |memo, page| memo + page.instances }
      end
      instances
    end

    def self.find_existing_always_on_instances
      find_existing.find_all{ |instance| instance.auto_scaling_type.nil? }
    end

    def self.online
      find_existing.reject{|instance| instance.status != 'online'}
    end

    private

    def self.create_instances_for(layer, instances_config, type)
      syncer = InstanceSyncer.new(
        layer: layer,
        instances_config: instances_config,
        type: type
      )
      removed_instances = syncer.remove_excess_instances
      syncer.create_new_instances
    end

    def self.get_instances_in(layer, type = nil)
      opsworks_client.describe_instances(layer_id: layer.layer_id).inject([]){ |memo, page| memo + page.instances }.find_all do |i|
        if type == 'always on'
          i.auto_scaling_type == nil
        elsif type == 'load based'
          i.auto_scaling_type == 'load'
        end
      end
    end

    def self.create_custom_tags
      if stack_custom_tags.empty?
        return
      end

      vpc = VPC.find_existing

      # ec2_client doesn't bring detached volumes, have to use opsworks_client
      resource_ids = [].concat(Stack.find_volume_ids)

      # opsworks_client doesn't bring the NAT instance, have to use ec2_client
      # note that there will be duplicated volumes in the array
      resp = ec2_client.describe_instances({
        dry_run: false,
        filters: [
          {
            name: "tag:opsworks:stack",
            values: [Stack.stack_parameters(vpc)[:name]]
          }
        ]
      })
      resp.reservations.each do |reservation|
        reservation.instances.each do |instance|
          resource_ids.push(instance.instance_id)
          instance.block_device_mappings.each do |volume|
            # only ebs count, ephemeral is free
            resource_ids.push(volume.ebs.volume_id)
          end
        end
      end

      ec2_client.create_tags({
          dry_run: false,
          resources: resource_ids,
          tags: stack_custom_tags
      })
    end
  end
end
