module Cluster
  class ConfigCreator
    VARIANTS = {
      small: {
        template: './templates/cluster_config_default.json.erb',

        description: 'Only appropriate to smoke-test deployment and process very small videos. Uses a storage layer to export a filesystem.',

        storage_instance_type: 't2.medium',
        storage_disk_size: '200',

        database_instance_type: 't2.medium',
        database_disk_size: '20',

        admin_instance_type: 't2.medium',

        workers_instance_type: 't2.medium',
        workers_instance_count: 2,

        engage_instance_type: 't2.medium',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '10',

        matterhorn_root_size: '20',
        matterhorn_workspace_size: '50'
      },

      medium: {
        template: './templates/cluster_config_default.json.erb',

        description: 'Appropriate for processing small workloads and testing capture agent integration. Uses a storage layer to export a filesystem.',

        storage_instance_type: 'c4.xlarge',
        storage_disk_size: '500',

        database_instance_type: 'c4.large',
        database_disk_size: '50',

        admin_instance_type: 'c4.xlarge',

        workers_instance_type: 'c4.xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '50',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '50'
      },

      large: {
        template: './templates/cluster_config_default.json.erb',

        description: 'Appropriate for large workloads, fairly expensive to deploy. Uses a storage layer to export a filesystem.',

        storage_instance_type: 'c4.8xlarge',
        storage_disk_size: '2000',

        database_instance_type: 'c4.large',
        database_disk_size: '100',

        admin_instance_type: 'c4.8xlarge',

        workers_instance_type: 'c4.8xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '50'
      },

      zadara_medium: {
        template: './templates/cluster_config_zadara.json.erb',

        description: 'Appropriate for processing small workloads and testing capture agent integration. Uses zadara storage - see README.zadara.md for instructions. ',

        database_instance_type: 'c4.large',
        database_disk_size: '50',

        admin_instance_type: 'c4.xlarge',

        workers_instance_type: 'c4.xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '50',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '50'
      },

      zadara_large: {
        template: './templates/cluster_config_zadara.json.erb',

        description: 'Appropriate for large workloads. Uses zadara storage - see README.zadara.md for instructions. ',

        database_instance_type: 'c4.large',
        database_disk_size: '100',

        admin_instance_type: 'c4.8xlarge',

        workers_instance_type: 'c4.8xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '50'
      },

      efs_small: {
        template: './templates/cluster_config_efs.json.erb',

        description: 'Only appropriate to smoke-test deployment and process very small videos. Uses efs storage, only works in us-west-2 for now',

        database_instance_type: 't2.medium',
        database_disk_size: '20',

        admin_instance_type: 't2.medium',

        workers_instance_type: 't2.medium',
        workers_instance_count: 2,

        engage_instance_type: 't2.medium',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '10',

        matterhorn_root_size: '20',
        matterhorn_workspace_size: '50'
      },

      efs_medium: {
        template: './templates/cluster_config_efs.json.erb',

        description: 'Appropriate for processing small workloads and testing capture agent integration. Uses efs storage, only works in us-west-2 for now',

        database_instance_type: 'c4.large',
        database_disk_size: '50',

        admin_instance_type: 'c4.xlarge',

        workers_instance_type: 'c4.xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '50',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '50'
      },

      efs_large: {
        template: './templates/cluster_config_efs.json.erb',

        description: 'Appropriate for large workloads. Uses efs storage, only works in us-west-2 for now',

        database_instance_type: 'c4.large',
        database_disk_size: '100',

        admin_instance_type: 'c4.8xlarge',

        workers_instance_type: 'c4.8xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '50'
      },
    }

    attr_reader :variant, :attributes

    def initialize(attributes = {})
      @attributes = attributes
      @variant = get_variant
    end

    def create
      variant_attributes = VARIANTS[variant]
      template = variant_attributes[:template]

      erb = Erubis::Eruby.new(File.read(template))
      base_secrets = %Q|, #{get_base_secrets_content}|

      all_attributes = attributes.merge(variant_attributes).merge(base_secrets_content: base_secrets)

      erb.result(all_attributes)
    end

    private

    def get_base_secrets_content
      begin
        Cluster::Assets.get_support_asset(
          file_name: 'base-secrets.json',
          bucket: Cluster::Base.cluster_config_bucket_name
        )
      rescue => e
        File.read('templates/base-secrets.json')
      end
    end

    def get_variant
      if VARIANTS.has_key?("#{attributes[:variant]}".to_sym)
        attributes[:variant].to_sym
      else
        :medium
      end
    end
  end
end
