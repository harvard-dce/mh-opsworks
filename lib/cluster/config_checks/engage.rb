module Cluster
  module ConfigChecks
    class Engage < NumberedLayer
      def self.shortname
        'engage'
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Engage)
