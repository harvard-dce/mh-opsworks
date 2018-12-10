module ClusterCreationHelpers
  def dummy_cluster_attributes
    {
      name: '',
      cidr_block_root: '',
      app_git_url: '',
      app_git_revision: '',
      default_users: '',
      subnet_azs: ['us-east-1a','us-east-1d','us-east-1f','us-east-1b'],
      include_analytics: true,
      cookbook_source_type: 's3',
      include_utility: true,
      base_public_ami_id: "ami-12345",
      base_private_ami_id: "ami-09876",
    }
  end
end
