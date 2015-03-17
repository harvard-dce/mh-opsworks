describe Cluster::Stack do
  include EnvironmentHelpers
  include ClientStubHelpers

  ['stop', 'start'].each do |action|
    context ".#{action}_all" do
      it "uses the opsworks client to #{action} the stack" do
        stack_id = 'a stack id'
        stack_double = double('A stack')
        allow(described_class).to receive(:find_existing).and_return(stack_double)
        allow(stack_double).to receive(:stack_id).and_return(stack_id)
        allow(Cluster::Stack).to receive(:find_or_create).and_return(stack_double)
        opsworks_client = stub_opsworks_client
        allow(opsworks_client).to receive("#{action}_stack")

        described_class.send("#{action}_all".to_sym)

        expect(opsworks_client).to have_received("#{action}_stack".to_sym).with(stack_id: stack_id)
      end
    end
  end

  context '.all' do
    it 'returns an enumerable list of stacks via the opsworks client' do
      existing_stack_id = 'a-stack-id'
      existing_vpc_id = 'a-vpc-id'

      opsworks = stub_opsworks_client do |opsworks|
        opsworks.stub_responses(
          :describe_stacks,
          stacks: [
            { stack_id: existing_stack_id, vpc_id: existing_vpc_id }
          ]
        )
      end

      all = described_class.all

      expect(all.map { |stack| stack.stack_id}).to include('a-stack-id')
      expect(all.map { |stack| stack.vpc_id}).to include('a-vpc-id')
      expect(all.first).to be_instance_of(Aws::OpsWorks::Stack)
    end
  end

  context '.find_or_create' do
    it 'finds an existing stack based on the vpc id and name' do
      existing_vpc_id = 'an-existing-vpc-id'
      existing_stack_name = 'an-existing-stack-name'
      stack_id = 'stack-id'
      vpc_name = 'a-vpc-name'
      cidr_block = 'a-cidr-block'
      stub_ec2_client_with_a_vpc(
        name: vpc_name, cidr_block: cidr_block, vpc_id: existing_vpc_id
      )

      stub_config_to_include(
        vpc: {name: vpc_name, cidr_block: cidr_block},
        stack: {name: existing_stack_name}
      )

      opsworks = stub_opsworks_client do |opsworks|
        opsworks.stub_responses(
          :describe_stacks,
          stacks: [
            { stack_id: stack_id, name: existing_stack_name, vpc_id: existing_vpc_id }
          ]
        )
      end

      expect(described_class.find_or_create.stack_id).to eq stack_id
    end
  end

  def stub_ec2_client_with_a_vpc(
    name: 'a-vpc-name',
    cidr_block: 'a-block',
    vpc_id: 'a-vpc-id'
  )
    stub_ec2_client do |ec2|
      ec2.stub_responses(
        :describe_vpcs,
        vpcs: [{
          vpc_id: vpc_id,
          cidr_block: cidr_block,
          tags: [
            key: 'Name',
            value: name
          ]
        }]
      )
    end
  end
end
