module Cluster
  module ConfigurationHelpers
    module ClassMethods
      def config
        Config.new
      end

      def root_config
        config.parsed
      end

      def rds_config
        config.parsed[:rds]
      end

      def vpc_config
        config.parsed[:vpc]
      end

      def deployment_private_ssh_key
        stack_custom_json[:deployment_private_ssh_key]
      end

      def app_config
        stack_config[:app]
      end

      def get_account_number
        iam_client.get_user.data.user.arn.match(/(\d+)/)[0]
      end

      def rds_db_instance_arn
        region = config.parsed[:region]
        %Q|arn:aws:rds:#{region}:#{get_account_number}:db:#{rds_name}|
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
        config.parsed_secrets
      end

      def stack_custom_json
        stack_config[:chef].fetch(:custom_json, {})
      end

      def dev_or_testing_cluster?
        ['development', 'test'].include?(stack_custom_json[:cluster_env])
      end

      def cluster_seed_bucket_name
        stack_custom_json[:cluster_seed_bucket_name]
      end

      def storage_config
        stack_custom_json.fetch(:storage, {})
      end

      def cluster_config_bucket_name
        stack_secrets[:cluster_config_bucket_name] ||
          config.parsed_secrets[:stack].fetch(:secrets, {})[:cluster_config_bucket_name]
      end

      def shared_asset_bucket_name
        stack_custom_json[:shared_asset_bucket_name]
      end

      def stack_chef_config
        stack_config.fetch(:chef, {})
      end

      def instances_config_in_layer(layer_shortname)
        layers_config.find do |layer|
          layer[:shortname] == layer_shortname
        end.fetch(:instances, {})
      end

      def stack_custom_tags
        stack_custom_json[:aws_custom_tags] || []
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
