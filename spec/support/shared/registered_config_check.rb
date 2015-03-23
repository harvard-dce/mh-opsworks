shared_examples_for 'a registered configuration check' do
  it 'and is included in the check registry' do
    expect(Cluster::Config.check_registry).to include(described_class)
  end
end
