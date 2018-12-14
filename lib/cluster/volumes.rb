module Cluster
  class Volumes < Base
    include Waiters

    def self.all
      stack = Stack.with_existing_stack
      find_by_stack(stack)
    end

    def self.find_by_stack(stack)
      opsworks_client.describe_volumes({stack_id: stack.stack_id}).volumes
    end

    def self.create_snapshot(volume)
      snapshot = ec2_client.create_snapshot({
         description: "Migration snapshot for #{volume[:ec2_volume_id]}, #{volume[:mount_point]}",
         volume_id: volume[:ec2_volume_id],
         tag_specifications: [
             resource_type: "snapshot",
             tags: stack_custom_tags
         ]
      })
      wait_until_volume_snapshot_completed(snapshot.snapshot_id)
      snapshot
    end

    def self.create_volume_from_snapshot(snapshot, availability_zone)
      volume = ec2_client.create_volume({
        snapshot_id: snapshot.snapshot_id,
        volume_type: 'gp2',
        availability_zone: availability_zone,
        tag_specifications: [
          resource_type: "volume",
          tags: stack_custom_tags
        ]
      })
      wait_until_volume_available(volume.volume_id)
      volume
    end

  end
end
