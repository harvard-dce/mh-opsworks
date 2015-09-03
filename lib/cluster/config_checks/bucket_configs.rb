module Cluster
  module ConfigChecks
    class NoSharedAssetBucketName < StandardError; end
    class NoClusterConfigBucketName < StandardError; end

    class BucketConfigs < Base
      def self.sane?
        if stack_custom_json.fetch(:shared_asset_bucket_name, '') == ''
          raise NoSharedAssetBucketName.new('You must define a shared_asset_bucket_name in your custom stack json')
        end

        if stack_secrets.fetch(:cluster_config_bucket_name, '') == ''
          raise NoClusterConfigBucketName.new('You must define a cluster_config_bucket_name in your custom stack json')
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::BucketConfigs)
