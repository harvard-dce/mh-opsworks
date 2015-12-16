module Cluster
  class RemoteConfigs < Base
    def self.all
      Cluster::Assets.list_objects_in(
        bucket: cluster_config_bucket_name
      ).find_all{|name| name.match(/^cluster_config/) }.sort
    end

    def self.all_with_human_names
      all.each do |config_name|
        config_name.gsub!('cluster_config-', '')
        config_name.gsub!('.json', '')
      end.sort
    end

    def self.find(name)
      all.find do |cluster_config|
        cluster_config[:name] == name
      end
    end
  end
end
