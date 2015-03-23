module Cluster
  module ConfigChecks
    class Database < NumberedLayer
      def self.sane?
        if ! layer_defined?
          raise LayerNotDefined.new('Database layer is missing')
        end

        if too_many_instances?
          raise TooManyInstancesInLayer.new('There are too many database instances')
        end

        if too_many_layers?
          raise TooManyLayers.new('There are too many database layers')
        end

        if no_volumes_defined?
          raise NoStorageVolumesDefined.new('The database layer has no volume_configurations and cannot store data persistently.')
        end
      end

      private

      def self.find_all_layers
        layers_config.find_all { |layer| layer[:type] == 'db-master' }
      end

    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Database)
