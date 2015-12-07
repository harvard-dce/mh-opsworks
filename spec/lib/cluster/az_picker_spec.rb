describe Cluster::AZPicker do
  it 'picks different AZs for the primary and secondary AZ' do
    allow(described_class).to receive(:all).and_return(['first_az', 'second_az'])
    picker = described_class.new

    expect(picker.primary_az).to be
    expect(picker.primary_az).not_to eq picker.secondary_az
  end
end
