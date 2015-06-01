module Cluster
  module ConfigChecks
    class NoNfsServerHost < StandardError; end
    class ConflictingStorageConfiguration < StandardError; end

    class Storage < NumberedLayer
      def self.sane?
        if external_storage?
          if storage_config[:nfs_server_host] == nil
            raise NoNfsServerHost.new("You've configured this cluster to use an external NFS server but there's no nfs_server_host defined")
          end
          if layer_defined?
            raise ConflictingStorageConfiguration.new("You've configured this cluster to use an external NFS server but there's a storage layer as well.")
          end
        else
          super
        end
      end

      def self.shortname
        'storage'
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Storage)
