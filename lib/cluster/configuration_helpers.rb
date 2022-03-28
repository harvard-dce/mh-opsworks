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

      def subnet_azs
        vpc_config[:subnet_azs]
      end

      def primary_az
        subnet_azs.split(',').map(&:strip)[0]
      end

      def secondary_az
        subnet_azs.split(',').map(&:strip)[1]
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

      def rds_db_cluster_arn
        region = config.parsed[:region]
        %Q|arn:aws:rds:#{region}:#{get_account_number}:cluster:#{rds_name}|
      end

      def rds_db_instance_arn(rds_instance_identifier)
        region = config.parsed[:region]
        %Q|arn:aws:rds:#{region}:#{get_account_number}:db:#{rds_instance_identifier}|
      end

      def rds_supports_performance_insights?
        # it's only the t2/t3 class options that don't support this now
        !(rds_config[:db_instance_class] =~ /db\.t(\d)/)
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

      def prod_cluster?
        stack_shortname.match(/prod|prd/i) or !dev_or_testing_cluster?
      end

      def skip_configtest?
        stack_custom_json[:skip_configtest]
      end

      def cluster_seed_bucket_name
        stack_custom_json[:cluster_seed_bucket_name]
      end

      def storage_config
        stack_custom_json.fetch(:storage, {})
      end

      def zadara_api_config
        stack_custom_json.fetch(:zadara_manage_api, {})
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

      def get_cookbook_source_s3_url(revision)
        revision_file_label = revision.gsub("/", "-")
        %Q|https://s3.amazonaws.com/#{shared_asset_bucket_name}/cookbooks/mh-opsworks-recipes-#{revision_file_label}.tar.gz|
      end

      def ibm_watson_config
        stack_custom_json[:ibm_watson_service_auth]
      end

      def peer_vpc_config
        stack_custom_json[:peer_vpcs]
      end

      def is_truthy(val)
        return ['true', '1'].include? val.to_s.downcase
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
