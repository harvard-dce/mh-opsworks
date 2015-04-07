module Cluster
  module ConfigChecks
    class Admin < NumberedLayer
      def self.shortname
        'admin'
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Admin)
