describe Cluster::ConfigCreator do
  include ClusterCreationHelpers

  it 'substitutes in values correctly' do
    variant_attributes = described_class::VARIANTS[:medium]
    creator = described_class.new(config_attributes)

    output = creator.create

    expect(output).to include(config_attributes[:name])
    expect(output).to include(config_attributes[:cidr_block_root])
    expect(output).to include(config_attributes[:app_git_url])
    expect(output).to include(config_attributes[:app_git_revision])
    expect(output).to include(variant_attributes[:storage_instance_type])
    expect(output).to include(config_attributes[:default_users])
  end

  it 'has multiple variants' do
    %i|small medium large|.each do |variant|
      variant_attributes = described_class::VARIANTS[variant]
      creator = described_class.new(dummy_cluster_attributes.merge(variant: variant))

      output = creator.create

      expect(output).to include(variant_attributes[:storage_instance_type])
    end
  end

  it 'has a default variant' do
    [' ', 'msadf', nil].each do |variant|
      creator = described_class.new(variant: variant)

      expect(creator.variant).to eq :medium
    end
  end

  it 'casts variants to symbols' do
    creator = described_class.new(variant: 'small')

    expect(creator.variant).to eq :small
  end

  it 'looks for a remote base-secrets.json during creation and integrates it if found' do
    base_secrets_content = '{"unique_string": "bar"}'
    allow(Cluster::Assets).to receive(:get_support_asset).and_return(base_secrets_content)

    variant_attributes = described_class::VARIANTS[:medium]

    creator = described_class.new(config_attributes)

    output = creator.create

    expect(output).to include("unique_string")
    expect(Cluster::Assets).to have_received(:get_support_asset)
  end

  def config_attributes
    name = 'A test name'
    cidr_block_root = '10.0.1'
    variant = :medium
    app_git_url = 'http://foobar'
    app_git_revision = 'unique_revision'
    default_users = 'afoasdf'

    attributes = {
      name: name,
      cidr_block_root: cidr_block_root,
      app_git_url: app_git_url,
      variant: variant,
      app_git_revision: app_git_revision,
      default_users: default_users
    }
  end
end
