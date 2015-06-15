module Cluster
  module NamingHelpers
    module ClassMethods
      def calculate_name(name)
        name.downcase.gsub(/[^a-z\d\-]/,'-')
      end

      def stack_shortname
        calculate_name(stack_config[:name])
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
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
