module Cluster
  module NamingHelpers
    module ClassMethods
      def calculate_name(name)
        name.downcase.gsub(/[^a-z\d\-]/,'-')
      end

      def topic_name
        stack_config[:name].downcase.gsub(/[^a-z\d\-_]/,'_')
      end

      def stack_shortname
        calculate_name(stack_config[:name])
      end

      def db_subnet_group_name
        %Q|#{stack_shortname}-db-subnet-group|
      end

      def rds_name
        %Q|#{stack_shortname}-cluster|
      end

      def rds_instance_prefix
        %Q|#{stack_shortname}-database|
      end

      def rds_cfn_stack_name
        %Q|#{stack_shortname}-rds|
      end

      def vpc_name
        %Q|#{stack_shortname}-vpc|
      end

      def cfn_stack_name_from_id(cfn_stack_id)
        cfn_stack_id.match(/stack\/([^\/]+)/).captures.first
      end

      def instance_profile_name
        %Q|#{stack_shortname}-instance-profile|
      end

      def service_role_name
        %Q|#{stack_shortname}-service-role|
      end

      def distribution_bucket_name
        stack_custom_json[:s3_distribution_bucket_name]
      end

      def s3_file_archive_bucket_name
        stack_custom_json[:s3_file_archive_bucket_name]
      end

      def s3_cold_archive_bucket_name
        stack_custom_json[:s3_cold_archive_bucket_name]
      end

      def analytics_es_snapshots_bucket_name
        %Q|#{stack_shortname}-snapshots|
      end

      def analytics_ua_harvester_bucket_name
        %Q|#{stack_shortname}-ua-harvester|
      end

      def useractions_queue_name
        %Q|#{stack_shortname}-user-actions|
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
