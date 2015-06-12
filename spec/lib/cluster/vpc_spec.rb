describe Cluster::VPC do
  include EnvironmentHelpers
  include ClientStubHelpers

  context '.all' do
    it 'uses the ec2 client' do
      stub_ec2_client do |ec2|
        ec2.stub_responses(
          :describe_vpcs,
          vpcs: [ { vpc_id: 'a-vpc-id'} ]
        )
      end
      all = described_class.all

      expect(all.map{|vpc| vpc.vpc_id}).to include 'a-vpc-id'
    end
  end

  context '.find_or_create' do
    it 'does not create a VPC if the name or cidr_block match another' do
      stub_ec2_client do |ec2|
        ec2.stub_responses(
          :describe_vpcs,
          { vpcs: [ existing_vpc ] }
        )
      end
      vpc_configs = [
        { name: 'test', cidr_block: '10.100.10.10/16' },
        { name: 'a-new-cluster', cidr_block: existing_cidr_block },
      ]

      vpc_configs.each do |vpc_config|
        stub_config_to_include(
          vpc: { cidr_block: vpc_config[:cidr_block] },
          stack: {
            name: vpc_config[:name]
          }
        )
        expect{ described_class.find_or_create }.to raise_error(
          Cluster::VpcConflictsWithAnother
        )
      end
    end

    it 'returns an existing VPC if the name and cidr_block match' do
      stub_config_to_include(stack: {
        name: 'test'
      })
      stub_ec2_client do |ec2|
        ec2.stub_responses(
          :describe_vpcs,
          { vpcs: [ existing_vpc ] }
        )
      end
      stub_config_to_include(
        vpc: { cidr_block: existing_cidr_block }
      )

      vpc = described_class.find_or_create

      expect(vpc.vpc_id).to eq existing_vpc[:vpc_id]
      expect(vpc.cidr_block).to eq existing_cidr_block
    end
  end

  def existing_vpc
    {
      vpc_id: 'a-vpc-id',
      cidr_block: existing_cidr_block,
      tags: [
        key: 'Name',
        value: existing_vpc_name
      ]
    }
  end

  def existing_vpc_name
    'test-vpc'
  end

  def existing_cidr_block
    '10.0.0.10/16'
  end

end
