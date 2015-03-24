module Cluster
  class Layers < Base
    def self.all
      stack = Stack.with_existing_stack
      stack.layers
    end

    def self.by_start_order
      layers = self.all
      layers_config.map do |layer|
        layers.find{|instantiated_layer| instantiated_layer.name == layer[:name]}
      end
    end

    def self.find_or_create
      layers_config.map do |layer|
        Layer.find_or_create(layer)
      end
    end
  end
end
