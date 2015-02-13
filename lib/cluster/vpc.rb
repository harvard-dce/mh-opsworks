require 'pry'
module Cluster
  class VPC < Base
    def self.all
      vpcs = []
      ec2.describe_vpcs.each do |page|
        page.vpcs.each do |vpc|
          vpcs << vpc
        end
      end
      vpcs
    end

    def self.create_or_initialize
      vpc = find_vpc
      return vpc if vpc

      if requested_vpc_has_conflicts_with_existing_one?
        raise VpcConflictsWithAnother
      else
        vpc = ec2.create_vpc(
          cidr_block: vpc_config[:cidr_block]
        ).first.vpc
        vpc_instance = Aws::EC2::Vpc.new(vpc.vpc_id, client: ec2)
        vpc_instance.create_tags(
          tags: [{ key: 'Name', value: vpc_config[:name] }]
        )
      end

      vpc
    end

    private

    def self.ec2
      @@ec2 ||= Aws::EC2::Client.new(
        region: config.json[:region],
        credentials: config.credentials
      )
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
      config.json[:vpc]
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
