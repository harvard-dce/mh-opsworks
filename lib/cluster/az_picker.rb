module Cluster
  class AZPicker < Base
    attr_reader :subnet_azs

    def initialize
      populate
    end

    private

    def populate
      azs = self.class.all
      @subnet_azs = azs.sample(4)
    end

    def self.all
      availability_zones = []
      ec2_client.describe_availability_zones.inject([]){ |memo, page| memo + page.availability_zones }.each do |az|
        availability_zones << az.zone_name
      end
      availability_zones
    end
  end
end
