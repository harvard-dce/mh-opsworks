module Cluster
  module ConfigChecks
    class ClusterIncompatible < StandardError; end

    class ClusterCompatibility < Base
      def self.sane?
        if ! vpc_config[:subnet_azs] || rds_config[:allocated_storage]
          raise ClusterIncompatible.new('This configuration appears to be for a cluster built with an older version of mh-opsworks.')
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::ClusterCompatibility)
