require 'pry'
module Cluster
  class VPC < Base
    def self.all
      vpcs = []
      ec2_client.describe_vpcs.each do |page|
        page.vpcs.each do |vpc|
          vpcs << construct_instance(vpc.vpc_id)
        end
      end
      vpcs
    end

    def self.find_or_create
      vpc = find_vpc
      if ! vpc
        if requested_vpc_has_conflicts_with_existing_one?
          raise VpcConflictsWithAnother
        end
        vpc = ec2_client.create_vpc(
          cidr_block: vpc_config[:cidr_block]
        ).first.vpc

        # TODO: wait semantics
        construct_instance(vpc.vpc_id).tap do |vpc_instance|
          create_vpc_tags(vpc_instance)
          create_subnets(vpc_instance)
        end
      end

      construct_instance(vpc.vpc_id)
    end

    private

    def self.create_vpc_tags(vpc_instance)
      vpc_instance.create_tags(
        tags: [{ key: 'Name', value: vpc_config[:name] }]
      )
    end

    def self.create_subnets(vpc_instance)
      vpc_instance.create_subnet(
        cidr_block: vpc_config[:cidr_block]
      )
    end

    def self.construct_instance(vpc_id)
      Aws::EC2::Vpc.new(vpc_id, client: ec2_client)
    end

    def self.requested_vpc_has_conflicts_with_existing_one?
      self.configured_vpc_matches_another_on_name? ||
        self.configured_vpc_matches_another_on_cidr_block?
    end

    def self.configured_vpc_matches_another_on_name?
      all.any? do |vpc|
        extract_name_from(vpc) == vpc_config[:name]
      end
    end

    def self.configured_vpc_matches_another_on_cidr_block?
      all.any? do |vpc|
        vpc.cidr_block == vpc_config[:cidr_block]
      end
    end

    def self.vpc_config
      config.parsed[:vpc]
    end

    def self.find_vpc
      all.find do |vpc|
        (vpc.cidr_block == vpc_config[:cidr_block]) &&
          (extract_name_from(vpc) == vpc_config[:name])
      end
    end

    def self.extract_name_from(vpc)
      name_tag = vpc.tags.find { |t| t.key == 'Name' }
      if name_tag
        name_tag.value
      end
    end
  end
end
