module Cluster
  module ConfigChecks
    class DatabaseMasterLayerNotDefined < StandardError; end
    class TooManyInstancesInDatabaseMasterLayer < StandardError; end
    class TooManyDatabaseLayers < StandardError; end

    class Database < Cluster::Base
      def self.sane?
        if ! database_master_layer_defined?
          raise DatabaseMasterLayerNotDefined
        end

        if too_many_instances?
          raise TooManyInstancesInDatabaseMasterLayer
        end

        if too_many_database_layers?
          raise TooManyDatabaseLayers
        end
      end

      private

      def self.find_db_layer
        stack_config[:layers].find { |layer| layer[:type] == 'db-master' }
      end

      def self.too_many_database_layers?
        db_layers = stack_config[:layers].find_all { |layer| layer[:type] == 'db-master' }
        db_layers.count != 1
      end

      def self.database_master_layer_defined?
        find_db_layer
      end

      def self.too_many_instances?
        find_db_layer[:instances][:number_of_instances].to_i != 1
      end

    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Database)
