module Cluster
  class Base
    def self.config
      @@config ||= Config.new
    end
  end
end
