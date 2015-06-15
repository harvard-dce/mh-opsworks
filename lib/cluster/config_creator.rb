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
        matterhorn_workspace_size: '100'
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
        workers_instance_count: 4,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '50',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '500'
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
        workers_instance_count: 5,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        matterhorn_root_size: '50',
        matterhorn_workspace_size: '500'
      }
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

      all_attributes = {
        name: attributes[:name],
        cidr_block_root: attributes[:cidr_block_root],
        app_git_url: attributes[:app_git_url],
        app_git_revision: attributes[:app_git_revision],
      }.merge(variant_attributes)

      erb.result(all_attributes)
    end

    private

    def get_variant
      if VARIANTS.has_key?("#{attributes[:variant]}".to_sym)
        attributes[:variant].to_sym
      else
        :medium
      end
    end
  end
end
