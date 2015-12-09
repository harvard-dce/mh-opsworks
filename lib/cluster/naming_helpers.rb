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
        %Q|#{stack_shortname}-database|
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

      def efs_filesystem_name
        %Q|#{vpc_name} efs filesystem|
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
