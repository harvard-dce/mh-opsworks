describe Cluster::ConfigCreator do
  it 'substitutes in values correctly' do
    name = 'A test name'
    cidr_block_root = '10.0.1'
    variant = :medium
    variant_attributes = described_class::VARIANTS[variant]
    app_git_url = 'http://foobar'
    app_git_revision = 'unique_revision'

    attributes = {
      name: name,
      cidr_block_root: cidr_block_root,
      app_git_url: app_git_url,
      variant: variant,
      app_git_revision: app_git_revision
    }

    creator = described_class.new(attributes)

    output = creator.create

    expect(output).to include(name)
    expect(output).to include(cidr_block_root)
    expect(output).to include(app_git_url)
    expect(output).to include(app_git_revision)
    expect(output).to include(variant_attributes[:storage_instance_type])
  end

  it 'has multiple variants' do
    %i|small medium large|.each do |variant|
      variant_attributes = described_class::VARIANTS[variant]
      creator = described_class.new(variant: variant)

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
end
