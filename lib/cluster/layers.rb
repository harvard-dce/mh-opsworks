module Cluster
  class Layers < Base
    def self.all
      stack = Stack.with_existing_stack
      stack.layers
    end

    def self.update
      stack = Stack.find_existing
      if stack
        layers_config.map do |layer|
          Layer.update(stack, layer)
        end
      end
    end

    def self.find_by_shortnames(names = [])
      all.find_all do |layer|
        names.include?(layer.shortname)
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
