require 'pry'
module Cluster
  class Console < Base
    def self.run
      binding.pry
    end
  end
end
