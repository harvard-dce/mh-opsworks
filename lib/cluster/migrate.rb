module Cluster
  class Migrate < Base
    include Waiters

    def self.migrate(source_name)
      source_stack = Cluster::Stack.find_by_name(source_name)

      if external_storage?
        puts "Can't migrate external shared storage"
      else
        migrate_shared_storage_volume(source_stack)
      end

      migrate_buckets
    end

    def self.migrate_shared_storage_volume(source_stack)

      storage_instance = Cluster::Instances.find_manageable_instances_by_layer_shortname(['storage']).first

      source_volume = Volumes.find_by_stack(source_stack).find do |volume|
        volume[:mount_point] == "/vol/ganglia" #storage_config[:export_root]
      end

      snapshot = Volumes.create_snapshot(source_volume)

      new_volume = Volumes.create_from_snapshot(snapshot, storage_instance.availability_zone)
    end
  end
end

