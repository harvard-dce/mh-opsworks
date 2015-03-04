module Cluster
  class Layers < Base
    def self.all
      Stack.find_or_create.layers
    end

    def self.find_or_create
      stack_config[:layers].map do |layer|
        Layer.find_or_create(layer)
      end
    end
  end
end
