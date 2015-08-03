module Cluster
  class Filesystem < Base
    def self.all
      efs_client.describe_file_systems.file_systems
    end

    def self.find_existing
      all.find do |file_system|
        file_system.name == efs_filesystem_name
      end
    end

    def self.primary_efs_ip_address
      mount_target = efs_client.describe_mount_targets(file_system_id: find_existing.file_system_id).mount_targets.first
      mount_target.ip_address
    end
  end
end
