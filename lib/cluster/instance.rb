module Cluster
  class Instance < Base
    include Waiters

    attr_reader :opsworks_instance_id

    def initialize(opsworks_instance_id)
      @opsworks_instance_id = opsworks_instance_id
    end

    def wait_for_instance_to_stop
      self.class.wait_until_opsworks_instances_stopped([opsworks_instance_id])
    end

    def stop
      self.class.opsworks_client.stop_instance(
        instance_id: opsworks_instance_id
      )
    end

    def delete
      self.class.opsworks_client.delete_instance(
        instance_id: opsworks_instance_id,
        delete_elastic_ip: true,
        delete_volumes: true
      )
    end

    def self.find_or_create_in_layer(layer, instances_config)
      vpc = Cluster::VPC.find_existing
      subnet =
        if layer.auto_assign_public_ips == false &&
            layer.auto_assign_elastic_ips == false
          # Private instance
          vpc.subnets.find{|subnet| subnet.cidr_block == vpc_config[:private_cidr_block] }
        else
          # Public instance
          vpc.subnets.find{|subnet| subnet.cidr_block == vpc_config[:public_cidr_block] }
        end

      instance_params = {
        stack_id: layer.stack_id,
        layer_ids: [layer.layer_id],
        subnet_id: subnet.subnet_id,
        root_device_type: instances_config.fetch(:root_device_type, 'instance-store'),
        instance_type: instances_config.fetch(:instance_type, 't2.micro')
      }
      opsworks_client.create_instance(instance_params)
    end
  end
end
