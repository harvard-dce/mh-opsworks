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

    def self.find_or_create_in_layer(layer, instances_config, type)
      vpc = Cluster::VPC.find_existing
      subnet = nil
      ami_info = {}

      if layer.auto_assign_public_ips == false &&
          layer.auto_assign_elastic_ips == false
        # Private instance
        subnet = vpc.subnets.find{|subnet| subnet.cidr_block == vpc_config[:private_cidr_block] }
        if stack_custom_json[:base_private_ami_id]
          ami_info[:os] = 'Custom'
          ami_info[:ami_id] = stack_custom_json[:base_private_ami_id]
        end
      else
        # Public instance
        subnet = vpc.subnets.find{|subnet| subnet.cidr_block == vpc_config[:public_cidr_block] }
        if stack_custom_json[:base_public_ami_id]
          ami_info[:os] = 'Custom'
          ami_info[:ami_id] = stack_custom_json[:base_public_ami_id]
        end
      end

      instance_params = {
        stack_id: layer.stack_id,
        layer_ids: [layer.layer_id],
        subnet_id: subnet.subnet_id,
        root_device_type: instances_config.fetch(:root_device_type, 'instance-store'),
        block_device_mappings: [
          {
            device_name: 'ROOT_DEVICE',
            ebs: {
              volume_size: instances_config.fetch(:root_device_size, 16),
              volume_type: 'gp2',
              delete_on_termination: true
            }
          }
        ],
        instance_type: instances_config.fetch(:instance_type, 't2.micro'),
        auto_scaling_type: (type == 'load based') ? 'load' : nil
      }.merge(ami_info)
      opsworks_client.create_instance(instance_params)
    end
  end
end
