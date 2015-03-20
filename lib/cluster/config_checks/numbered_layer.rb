module Cluster
  module ConfigChecks
    class LayerNotDefined < StandardError; end
    class TooManyInstancesInLayer < StandardError; end
    class TooManyLayers < StandardError; end
    class NoStorageVolumesDefined < StandardError; end

    class NumberedLayer < Cluster::Base
      private

      def self.no_volumes_defined?
        layer = find_layer
        ! layer.has_key?(:volume_configurations) ||
          layer[:volume_configurations].empty?
      end

      def self.find_layer
        find_all_layers.first
      end

      def self.too_many_layers?
        db_layers = find_all_layers
        db_layers.count > 1
      end

      def self.layer_defined?
        find_layer
      end

      def self.too_many_instances?
        find_layer[:instances][:number_of_instances].to_i > 1
      end

    end
  end
end
