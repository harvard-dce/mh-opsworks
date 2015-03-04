module Cluster
  class InstanceSyncer < Base
    include Waiters

    attr_reader :layer, :instances_config, :desired_number_of_instances

    def initialize(layer:, instances_config:)
      @layer = layer
      @instances_config = instances_config
      @desired_number_of_instances = instances_config.fetch(:number_of_instances, 0).to_i
    end

    def remove_excess_instances
      instance_count_delta_memo = instance_count_delta
      if instance_count_delta_memo < 0
        instance_count_delta_memo.abs.times do
          to_remove = get_oldest_instance
          stop_instance(to_remove)

          if to_remove.ec2_instance_id != nil
            self.class.when_instance_stopped(to_remove.instance_id) do
              remove_instance(to_remove)
            end
          else
            # It's not been spun up. Get rid of it.
            remove_instance(to_remove)
          end
        end
      end
    end

    def create_new_instances
      instance_count_delta.times.map do
        Cluster::Instance.find_or_create_in_layer(layer, instances_config)
      end
    end

    private

    def instances_in_layer
      Instances.get_instances_in(layer)
    end

    def get_oldest_instance
      instances_in_layer.sort_by do |instance|
        DateTime.parse(instance.created_at)
      end.first
    end

    def stop_instance(instance)
      self.class.opsworks_client.stop_instance(
        instance_id: instance.instance_id
      )
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
