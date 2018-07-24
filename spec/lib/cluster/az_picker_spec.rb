describe Cluster::AZPicker do
  it 'picks a random sample of 4 available AZs' do
    allow(described_class).to receive(:all).and_return(['foo', 'far', 'faz', 'bar', 'baz', 'blerg', 'boo'])
    picker = described_class.new

    expect(picker.subnet_azs).to be_an_instance_of(Array)
    expect(picker.subnet_azs.length).to eq 4
    expect(Cluster::AZPicker.all).to include(*picker.subnet_azs)
  end
end
