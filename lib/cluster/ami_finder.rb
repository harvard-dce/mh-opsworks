module Cluster
  require 'colorize'
  class AmiFinder < Base

    attr_reader :public, :private

    def initialize
      populate
    end

    def populate
      amis = self.class.all
      begin
        @private = amis.find { |image| image.name.match(/private[-_]ocopsworks_base/) }.image_id
        @public = amis.find { |image| image.name.start_with?('ocopsworks_base') }.image_id
      rescue => e
        puts e
        puts "Warning: Could not find appropriate public/private amis!".colorize(:red)
      end
    end

    def self.all
      amis = []
      params = {
          owners: ["self"],
          filters: [
              { name: "tag-key", values: ["mh-opsworks"] },
              { name: "tag:released", values: ["1"] }
          ]
      }
      ec2_client.describe_images(params).inject([]){ |memo, page| memo + page.images }.each do |image|
        amis << image
      end
      amis.sort_by(&:creation_date).reverse
    end
  end
end
