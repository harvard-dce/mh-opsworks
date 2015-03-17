module Cluster
  class Layers < Base
    def self.all
      stack = Stack.with_existing_stack
      stack.layers
    end

    def self.find_or_create
      stack_config[:layers].map do |layer|
        Layer.find_or_create(layer)
      end
    end
  end
end
