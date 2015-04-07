module Cluster
  module ConfigChecks
    class Monitoring < NumberedLayer
      def self.shortname
        'monitoring-master'
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Monitoring)
