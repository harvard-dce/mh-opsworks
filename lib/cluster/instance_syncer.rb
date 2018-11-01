module Cluster
  class InstanceSyncer < Base
    include Waiters

    attr_reader :layer, :instances_config, :desired_number_of_instances, :type

    def initialize(layer: nil, instances_config: nil, type: nil)
      @layer = layer
      @instances_config = instances_config
      @type = type
      if type == 'always on'
        @desired_number_of_instances = instances_config.fetch(:number_of_instances, 0).to_i
      else
        @desired_number_of_instances = instances_config[:scaling].fetch(:number_of_scaling_instances, 0).to_i
      end
    end

    def remove_excess_instances
      instance_count_delta_memo = instance_count_delta
      if instance_count_delta_memo < 0
        instance_count_delta_memo.abs.times do
          to_remove = get_oldest_instance

          instance = Cluster::Instance.new(to_remove.instance_id)
          instance.stop
          puts 'waiting for instance to stop. . .'
          sleep 30
          instance.wait_for_instance_to_stop
          instance.delete
        end
      end
    end

    def create_new_instances
      vpc = Cluster::VPC.find_existing
      instance_count_delta.times.map do |i|

        if layer.auto_assign_public_ips == false && layer.auto_assign_elastic_ips == false
          private_subnet_cidr_blocks = Cluster::VPC.get_private_subnet_cidr_blocks
          subnets = vpc.subnets.find_all { |subnet|
            private_subnet_cidr_blocks.include? subnet.cidr_block
          }.shuffle

          # do basic round-robin selection from available subnets
          subnet = subnets[i % subnets.length]
        else
          public_subnet_cidr_block = Cluster::VPC.get_public_subnet_cidr_blocks.first
          subnet = vpc.subnets.find{|subnet| subnet.cidr_block == public_subnet_cidr_block }
        end

        Cluster::Instance.find_or_create_in_layer(layer, instances_config, type, subnet)
      end
    end

    private

    def instances_in_layer
      Instances.get_instances_in(layer, type) || []
    end

    def get_oldest_instance
      instances_in_layer.sort_by do |instance|
        DateTime.parse(instance.created_at)
      end.first
    end

    def remove_instance(instance)
      self.class.opsworks_client.delete_instance(
        instance_id: instance.instance_id,
        delete_elastic_ip: true,
        delete_volumes: true
      )
    end

    def instance_count_delta
      desired_number_of_instances - instances_in_layer.count
    end
  end
end
