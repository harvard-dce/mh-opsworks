module Cluster
  class ConfigCreator
    DEFAULT_VARIANT = :medium

    VARIANTS = {
      small: {
        template: './templates/cluster_config_default.json.erb',

        description: 'Only appropriate to smoke-test deployment and process very small videos. Uses a storage layer to export a filesystem.',

        storage_instance_type: 't2.medium',
        storage_disk_size: '100',

        database_instance_type: 'db.t2.medium',
        database_disk_size: '20',
        multi_az: false,

        admin_instance_type: 't2.medium',

        workers_instance_type: 't2.medium',
        workers_instance_count: 2,

        engage_instance_type: 't2.medium',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '10',

        analytics_instance_type: 't2.large',
        analytics_disk_size: '20',

        opencast_root_size: '20',
        root_device_size: '8',
        opencast_workspace_size: '50'
      },

      medium: {
        template: './templates/cluster_config_default.json.erb',

        description: 'Appropriate for processing small workloads and testing capture agent integration. Uses a storage layer to export a filesystem.',

        storage_instance_type: 'c4.xlarge',
        storage_disk_size: '250',

        database_instance_type: 'db.t2.medium',
        database_disk_size: '20',
        multi_az: false,

        admin_instance_type: 'c4.xlarge',

        workers_instance_type: 'c4.xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '20',

        analytics_instance_type: 'm4.large',
        analytics_disk_size: '50',

        opencast_root_size: '20',
        root_device_size: '8',
        opencast_workspace_size: '50'
      },

      large: {
        template: './templates/cluster_config_default.json.erb',

        description: 'Appropriate for large workloads, fairly expensive to deploy. Uses a storage layer to export a filesystem.',

        storage_instance_type: 'c4.8xlarge',
        storage_disk_size: '2000',

        database_instance_type: 'db.m4.2xlarge',
        database_disk_size: '250',
        multi_az: true,

        admin_instance_type: 'c4.8xlarge',

        workers_instance_type: 'c4.8xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        analytics_instance_type: 'm4.xlarge',
        analytics_disk_size: '500',

        opencast_root_size: '50',
        root_device_size: '16',
        opencast_workspace_size: '250'
      },

      zadara_medium: {
        template: './templates/cluster_config_zadara.json.erb',

        description: 'Appropriate for processing small workloads and testing capture agent integration. Uses zadara storage - see README.zadara.md for instructions. ',

        database_instance_type: 'db.t2.medium',
        database_disk_size: '20',
        multi_az: false,

        admin_instance_type: 'c4.xlarge',

        workers_instance_type: 'c4.xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '20',

        analytics_instance_type: 'm4.large',
        analytics_disk_size: '50',

        opencast_root_size: '20',
        root_device_size: '8',
        opencast_workspace_size: '50'
      },

      zadara_large: {
        template: './templates/cluster_config_zadara.json.erb',

        description: 'Appropriate for large workloads. Uses zadara storage - see README.zadara.md for instructions. ',

        database_instance_type: 'db.m4.2xlarge',
        database_disk_size: '250',
        multi_az: true,

        admin_instance_type: 'c4.8xlarge',

        workers_instance_type: 'c4.8xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        analytics_instance_type: 'm4.xlarge',
        analytics_disk_size: '500',

        opencast_root_size: '50',
        root_device_size: '16',
        opencast_workspace_size: '250'
      },

      efs_small: {
        template: './templates/cluster_config_efs.json.erb',

        description: 'Only appropriate to smoke-test deployment and process very small videos. Uses efs storage, only works in us-west-2 for now',

        database_instance_type: 'db.t2.medium',
        database_disk_size: '20',
        multi_az: false,

        admin_instance_type: 't2.medium',

        workers_instance_type: 't2.medium',
        workers_instance_count: 2,

        engage_instance_type: 't2.medium',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '10',

        opencast_root_size: '20',
        root_device_size: '8',
        opencast_workspace_size: '50'
      },

      efs_medium: {
        template: './templates/cluster_config_efs.json.erb',

        description: 'Appropriate for processing small workloads and testing capture agent integration. Uses efs storage, only works in us-west-2 for now',

        database_instance_type: 'db.t2.large',
        database_disk_size: '50',
        multi_az: false,

        admin_instance_type: 'c4.xlarge',

        workers_instance_type: 'c4.xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.xlarge',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '50',

        opencast_root_size: '50',
        root_device_size: '8',
        opencast_workspace_size: '50'
      },

      efs_large: {
        template: './templates/cluster_config_efs.json.erb',

        description: 'Appropriate for large workloads. Uses efs storage, only works in us-west-2 for now',

        database_instance_type: 'db.m4.xlarge',
        database_disk_size: '250',
        multi_az: true,

        admin_instance_type: 'c4.8xlarge',

        workers_instance_type: 'c4.8xlarge',
        workers_instance_count: 2,

        engage_instance_type: 'c4.8xlarge',

        ganglia_instance_type: 'c4.large',
        ganglia_disk_size: '100',

        opencast_root_size: '50',
        root_device_size: '16',
        opencast_workspace_size: '50'
      },

      ami_builder: {
        template: './templates/cluster_config_ami_builder.json.erb',

        description: 'Use this to build a custom AMI for use by other clusters',

        storage_instance_type: 't2.medium',
        storage_disk_size: '200',

        database_instance_type: 'db.t2.micro',
        database_disk_size: '20',
        multi_az: false,

        admin_instance_type: 't2.medium',

        workers_instance_type: 't2.medium',
        workers_instance_count: 2,

        engage_instance_type: 't2.medium',

        ganglia_instance_type: 't2.medium',
        ganglia_disk_size: '10',

        opencast_root_size: '20',
        root_device_size: '8',
        opencast_workspace_size: '50'
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
      base_secrets = %Q|, #{get_base_secrets_content}|

      all_attributes = attributes.merge(variant_attributes).
        merge(project_tag).
        merge(base_secrets_content: base_secrets).
        merge(database_user_info).
        merge(s3_distribution_bucket_name_from(attributes[:name])).
        merge(s3_file_archive_bucket_name_from(attributes[:name])).
        merge(analytics_layer_content)

      erb.result(all_attributes)
    end

    private

    def analytics_layer_content
      {
        analytics_layer_template: File.read('templates/analytics_layer.json.erb')
      }
    end

    def project_tag
      if attributes[:project_tag].nil? || attributes[:project_tag].empty?
        tag = "MH"
      else
        tag = attributes[:project_tag]
      end
      {
        project_tag: tag
      }
    end

    def s3_distribution_bucket_name_from(name)
      {
        s3_distribution_bucket_name: %Q|#{Cluster::Base.calculate_name(name)}-distribution|
      }
    end

    def s3_file_archive_bucket_name_from(name)
      {
        s3_file_archive_bucket_name: %Q|#{Cluster::Base.calculate_name(name)}-file-archive|
      }
    end

    def database_user_info
      password = ''
      16.times do
        password += (('a'..'z').to_a + (1..9).to_a).sample.to_s
      end

      { master_user_password: password }
    end

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
