module Cluster
  module ConfigChecks
    class LayerNotDefined < StandardError; end
    class TooManyInstancesInLayer < StandardError; end
    class TooManyLayers < StandardError; end
    class NoStorageVolumesDefined < StandardError; end

    class NumberedLayer < Cluster::Base

      def self.sane?
        if ! layer_defined?
          raise LayerNotDefined.new("#{klass_name} layer is missing")
        end

        if too_many_instances?
          raise TooManyInstancesInLayer.new("There are too many #{klass_name} instances")
        end

        if too_many_layers?
          raise TooManyLayers.new("There are too many #{klass_name} layers")
        end

        if no_volumes_defined?
          raise NoStorageVolumesDefined.new("The #{klass_name} layer has no volume_configurations and cannot store data persistently.")
        end
      end

      private

      def self.klass_name
        name.split('::').last
      end

      def self.find_all_layers
        layers_config.find_all { |layer| layer[:shortname] == shortname }
      end

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
