module Cluster
  module ConfigChecks
    class Storage < NumberedLayer
      def self.shortname
        'storage'
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Storage)
