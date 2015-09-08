module Cluster
  class RemoteConfig < Base
    class StillExists < StandardError; end

    include ConfigurationHelpers

    # All checks for cluster uniqueness on CIDR block, name, and other
    # attributes should happen upstream. This assumes you've already chosen
    # values that make sense.
    def self.create(attributes = {})
      config_file_name = cluster_config_name(attributes[:name])
      creator = ConfigCreator.new(attributes)
      templatted_output = creator.create

      File.open(config_file_name, 'w', 0600) do |fh|
        fh.write JSON.pretty_generate(JSON.parse(templatted_output))
        fh.write "\n"
      end

      config_file_name
    end

    def initialize
      initialize_config_object
    end

    def local_version
      config.version
    end

    def config_state
      remote_version_memo = remote_version
      if remote_version_memo.nil? || (remote_version_memo == local_version)
        if changeset != ''
          :newer_than_remote
        else
          :current
        end
      elsif remote_version_memo > local_version
        :behind_remote
      end
    end

    def remote_version
      config = remote_config_contents
      if config
        parse_config(config)[:version].to_i
      end
    end

    def changeset
      Diffy::Diff.new(remote_config_contents, local_config_contents, context: 5).to_s
    end

    def changed?
      changeset != ''
    end

    def remote_config_contents
      Cluster::Assets.get_support_asset(
        file_name: active_cluster_config_name,
        bucket: cluster_config_bucket_name
      )
    end

    def local_config_contents
      config.config_content
    end

    def delete
      local_config_file = config.active_config
      if Cluster::VPC.find_existing
        raise StillExists.new(
          "The cluster still exists. You can't remove a cluster config until the VPC, stack, and other resources have been removed"
        )
      end
      Cluster::Assets.delete_support_asset(
        file_name: active_cluster_config_name,
        bucket: cluster_config_bucket_name
      )
      Cluster::RcFileSwitcher.new.delete
      if File.exists?(local_config_file)
        File.unlink(local_config_file)
      end
    end

    def download
      contents = remote_config_contents

      File.open(config.active_config, 'w', 0600) do |fh|
        fh.write contents
      end
    end

    def update_efs_server_hostname(hostname)
      current_config = config
      current_values = current_config.parsed

      current_values[:stack][:chef][:custom_json][:storage][:nfs_server_host] = hostname
      write_config_with(current_values)
      initialize_config_object
    end

    def sync
      current_config = config
      current_values = current_config.parsed

      new_version = current_config.version + 1
      current_values[:version] = new_version

      write_config_with(current_values)

      Cluster::Assets.publish_support_asset_to(
        file_name: current_config.active_config,
        bucket: cluster_config_bucket_name
      )
    end

    def active_cluster_config_name
      self.class.cluster_config_name(self.class.stack_shortname)
    end

    private

    attr_reader :config

    def initialize_config_object
      @config = Cluster::Config.new
    end

    def write_config_with(config_values)
      json_output = JSON.pretty_generate(config_values)

      File.open(config.active_config, 'w', 0600) do |fh|
        fh.write json_output
        fh.write "\n"
      end
    end

    def parse_config(config)
      JSON.parse(config, symbolize_names: true)
    end

    def cluster_config_bucket_name
      self.class.cluster_config_bucket_name
    end

    def self.cluster_config_name(cluster_name)
      %Q|cluster_config-#{calculate_name(cluster_name)}.json|
    end
  end
end
