describe Cluster::Stack do
  include EnvironmentHelpers
  include ClientStubHelpers

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
    it 'is successful' do
      stub_vpc_instance_with_subnet_id

      stub_ec2_client do |ec2|
        ec2.stub_responses(
          :create_vpc,
          vpc: { vpc_id: 'an-id'}
        )
      end
      stack = described_class.find_or_create

      expect(stack).to be_instance_of(Aws::OpsWorks::Stack)
    end

    it 'auto creates the relevant service role if it does not exist' do
      stub_ec2_client_with_a_vpc
      stub_config_to_include(
        stack: {name: 'an-amazing-stack'}
      )

    end

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

  def stub_vpc_instance_with_subnet_id(subnet_id = 'subnet-id')
      vpc_instance = double('vpc instance').as_null_object
      allow(vpc_instance).to receive(:vpc_id).and_return('a-vpc-id')
      allow(vpc_instance).to receive_message_chain(
        :subnets, :first, :id
      ).and_return(subnet_id)
      allow(Aws::EC2::Vpc).to receive(:new).and_return(vpc_instance)
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
