module ClusterCreationHelpers
  def dummy_cluster_attributes
    {
      name: '',
      cidr_block_root: '',
      app_git_url: '',
      app_git_revision: '',
      default_users: '',
      primary_az: 'us-east-1a',
      secondary_az: 'us-east-1d',
      include_analytics: true,
      cookbook_source_type: 's3'
    }
  end
end
