module Cluster
  module NamingHelpers
    module ClassMethods
      def instance_profile_name
        %Q|#{service_role_name}-instance-profile|
      end
    end

    def service_role_name
      service_role_config[:name]
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
