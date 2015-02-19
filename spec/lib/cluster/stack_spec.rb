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
    end
  end

  context '.find_or_create' do
    it 'is successful' do
      stub_ec2_client do |ec2|
        ec2.stub_responses(
          :create_vpc,
          vpc: { vpc_id: 'an-id'}
        )
      end
      stack = described_class.find_or_create

      expect(stack.stack_id).to be
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

    it 'finds a VPC and uses it to create the stack' do
      vpc_id = 'a-vpc-id'
      vpc_name = 'a-vpc'
      cidr_block = 'a-block'
      stub_config_to_include(vpc: { name: vpc_name, cidr_block: cidr_block } )

      stub_ec2_client_with_a_vpc(
        vpc_id: vpc_id, name: vpc_name, cidr_block: cidr_block
      )

      opsworks = stub_opsworks_client do |opsworks|
        opsworks.stub_responses(
          :create_stack,
          { stack_id: 'a-stack-id' }
        )
        allow(opsworks).to receive(:create_stack)
      end

      described_class.find_or_create

      expect(opsworks).to have_received(:create_stack).with(
        a_hash_including(vpc_id: vpc_id)
      )
    end

    it 'uses values from the configuration to create the stack' do
      region = 'a-region'
      name = 'test-stack'
      stub_config_to_include(
        region: region,
        stack: {
          name: name
        }
      )
      vpc_id = 'a-vpc-id'
      vpc_name = 'a-vpc'
      cidr_block = 'a-block'
      stub_config_to_include(vpc: { name: vpc_name, cidr_block: cidr_block } )

      stub_ec2_client_with_a_vpc(
        vpc_id: vpc_id, name: vpc_name, cidr_block: cidr_block
      )

      opsworks = stub_opsworks_client do |opsworks|
        opsworks.stub_responses(
          :create_stack,
          { stack_id: 'a-stack-id' }
        )
        allow(opsworks).to receive(:create_stack)
      end

      described_class.find_or_create

      expect(opsworks).to have_received(:create_stack).with(
        a_hash_including(
          region: region,
          name: name
        )
      )
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
