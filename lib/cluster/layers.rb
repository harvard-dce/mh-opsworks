module Cluster
  class Layers < Base
    def self.all
      Stack.find_or_create.layers
    end

    def self.as_configured
      stack_config[:layers].map do |layer|
        Layer.new(layer)
      end
    end
  end
end
