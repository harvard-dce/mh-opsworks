describe Cluster::InstanceProfile do
  include ClientStubHelpers
  include EnvironmentHelpers

  context '.all' do
    it 'returns a list of Aws::IAM::InstanceProfile objects' do
      stub_with_instance_profile_named('whatever')

      instance_profiles = described_class.all
      expect(instance_profiles.first).to be_instance_of(Aws::IAM::InstanceProfile)
    end
  end

  context '.delete' do
    it 'deletes correctly' do
      stub_with_instance_profile_named('service-role-instance-profile')
      stub_config_to_include(
        stack: {
          service_role: {
            name: 'service-role'
          }
        }
      )
      instance_profile_double = double('instance_profile')
      allow(instance_profile_double).to receive(:delete)
      allow(instance_profile_double).to receive(:roles).and_return([])
      allow(Aws::IAM::InstanceProfile).to receive(:new).and_return(instance_profile_double)

      described_class.delete

      expect(instance_profile_double).to have_received(:delete)
    end
  end

  def stub_with_instance_profile_named(name)
    stub_iam_client do |iam_client|
      iam_client.stub_responses(
        :list_instance_profiles,
        {
          instance_profiles: [
            { instance_profile_name: name}
          ]
        }
      )
    end
  end

end
