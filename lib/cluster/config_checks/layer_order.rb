module Cluster
  module ConfigChecks
    class DatabaseLayerLate < StandardError; end
    class StorageLayerLate < StandardError; end

    class LayerOrder < Base
      def self.sane?
        first_two = layers_config.slice(0,2)

        missing_layers = [ database_layer_config, storage_layer_config ] - first_two

        if missing_layers.include?(database_layer_config)
          raise DatabaseLayerLate.new('The database layer must be defined as one of the first layers to be available to other nodes when booting')
        end

        if missing_layers.include?(storage_layer_config)
          raise StorageLayerLate.new('The storage layer must be defined as one of the first layers to be available to other nodes when booting')
        end
      end

      private

      def self.database_layer_config
        layers_config.find{|layer| layer[:shortname] == 'db-master'}
      end

      def self.storage_layer_config
        layers_config.find{|layer| layer[:shortname] == 'storage'}
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::LayerOrder)
