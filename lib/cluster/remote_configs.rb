module Cluster
  class RemoteConfigs < Base
    def self.all
      Cluster::Assets.list_objects_in(
        bucket: cluster_config_bucket_name
      ).find_all{|name| name.match(/^cluster_config/) }
    end

    def self.find(name)
      all.find do |cluster_config|
        cluster_config[:name] == name
      end
    end
  end
end
