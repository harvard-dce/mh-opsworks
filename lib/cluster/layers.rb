module Cluster
  class Layers < Base
    def self.all
      stack = Stack.with_existing_stack
      stack.layers
    end

    def self.update
      stack = Stack.with_existing_stack
      layers_config.map do |layer|
        Layer.update(stack, layer)
      end
    end

    def self.find_or_create
      stack = Stack.with_existing_stack
      layers_config.map do |layer|
        Layer.find_or_create(stack, layer)
      end
    end
  end
end
