module Cluster
  module NamingHelpers
    module ClassMethods
      def stack_shortname
        stack_config[:shortname]
      end

      def vpc_name
        %Q|#{stack_shortname}-vpc|
      end

      def instance_profile_name
        %Q|#{stack_shortname}-instance-profile|
      end

      def service_role_name
        %Q|#{stack_shortname}-service-role|
      end

      def shared_asset_bucket_name
        stack_custom_json[:shared_asset_bucket_name]
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
