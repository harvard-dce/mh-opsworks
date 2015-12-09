module Cluster
  module ConfigChecks
    class NotAllBaseLayersDeployedTo < StandardError; end

    class Deployment < Base
      def self.sane?
        layers = deployment_config.fetch(:to_layers)

        if (base_layers - layers).any?
          raise NotAllBaseLayersDeployedTo.new(
            "Some base layers are not configured to be deployed to: #{(base_layers - layers).join(', ')}"
          )
        end
      end

      private

      def self.base_layers
        ['Admin', 'Engage', 'Workers']
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Deployment)
