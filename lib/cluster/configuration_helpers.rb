module Cluster
  module ConfigurationHelpers
    module ClassMethods
      def config
        Config.new
      end

      def root_config
        config.parsed
      end

      def vpc_config
        config.parsed[:vpc]
      end

      def deployment_private_ssh_key
        config.parsed_secrets[:deployment_private_ssh_key]
      end

      def app_config
        stack_config[:app]
      end

      def deployment_config
        app_config[:deployment]
      end

      def stack_config
        config.parsed[:stack]
      end

      def layers_config
        stack_config[:layers]
      end

      def stack_secrets
        config.parsed_secrets[:stack].fetch(:secrets, {})
      end

      def stack_custom_json
        stack_config[:chef].fetch(:custom_json, {}).merge(stack_secrets)
      end

      def storage_config
        stack_custom_json.fetch(:storage, {})
      end

      def cluster_config_bucket_name
        stack_secrets[:cluster_config_bucket_name]
      end

      def shared_asset_bucket_name
        stack_secrets[:shared_asset_bucket_name]
      end

      def stack_chef_config
        stack_config.fetch(:chef, {})
      end

      def instances_config_in_layer(layer_shortname)
        layers_config.find do |layer|
          layer[:shortname] == layer_shortname
        end.fetch(:instances, {})
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
