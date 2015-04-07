module Cluster
  module ConfigChecks
    class Database < NumberedLayer
      def self.shortname
        'db-master'
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Database)
