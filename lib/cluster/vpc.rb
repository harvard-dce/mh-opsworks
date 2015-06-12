require 'pry'
module Cluster
  class VPC < Base
    include Cluster::Waiters

    def self.all
      vpcs = []
      ec2_client.describe_vpcs.inject([]){ |memo, page| memo + page.vpcs }.each do |vpc|
        vpcs << construct_instance(vpc.vpc_id)
      end
      vpcs
    end

    def self.delete
      vpc = find_existing
      if vpc
        stack = cloudformation_client.describe_stacks.inject([]){ |memo, page| memo + page.stacks }.find do |stack|
          stack.stack_name == vpc_name
        end

        cloudformation_client.delete_stack(
          stack_name: stack.stack_id
        )
        wait_until_stack_delete_completed(stack.stack_id)
      end
    end

    def self.find_or_create
      vpc = find_existing
      if ! vpc
        if requested_vpc_has_conflicts_with_existing_one?
          raise VpcConflictsWithAnother
        end

        stack = cloudformation_client.create_stack(
          stack_name: vpc_name,
          template_body: File.read('./templates/OpsWorksinVPC.template'),
          parameters: [
            {
              parameter_key: 'CIDRBlock',
              parameter_value: vpc_config[:cidr_block]
            },
            {
              parameter_key: 'PublicCIDRBlock',
              parameter_value: vpc_config[:public_cidr_block]
            },
            {
              parameter_key: 'PrivateCIDRBlock',
              parameter_value: vpc_config[:private_cidr_block]
            },
          ],
          timeout_in_minutes: 15,
          tags: [
            {
              key: 'opsworks:stack',
              value: stack_config[:name]
            }
          ]
        )
        wait_until_stack_build_completed(stack.stack_id)
      end

      find_existing
    end

    def self.find_existing
      all.find do |vpc|
        (vpc.cidr_block == vpc_config[:cidr_block]) &&
          (extract_name_from(vpc) == vpc_name)
      end
    end

    private

    def self.construct_instance(vpc_id)
      Aws::EC2::Vpc.new(vpc_id, client: ec2_client)
    end

    def self.requested_vpc_has_conflicts_with_existing_one?
      self.configured_vpc_matches_another_on_name? ||
        self.configured_vpc_matches_another_on_cidr_block?
    end

    def self.configured_vpc_matches_another_on_name?
      all.any? do |vpc|
        extract_name_from(vpc) == vpc_name
      end
    end

    def self.configured_vpc_matches_another_on_cidr_block?
      all.any? do |vpc|
        vpc.cidr_block == vpc_config[:cidr_block]
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
