module Cluster
  module ConfigurationHelpers
    module ClassMethods
      def config
        @@config ||= Config.new
      end

      def root_config
        config.parsed
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

      def stack_chef_config
        stack_config.fetch(:chef, {})
      end

      def service_role_config
        config.parsed[:stack][:service_role]
      end

      def service_role_name
        service_role_config[:name]
      end

      def instances_config_in_layer(layer_name)
        stack_config[:layers].find do |layer|
          layer[:name] == layer_name
        end.fetch(:instances, {})
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
