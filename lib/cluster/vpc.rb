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
      stack = cloudformation_client.describe_stacks.inject([]){ |memo, page| memo + page.stacks }.find do |stack|
        stack.stack_name == vpc_name
      end

      if stack
        cloudformation_client.delete_stack(
          stack_name: stack.stack_id
        )
        wait_until_stack_delete_completed(stack.stack_id)
      end
    end

    def self.update
      parameters = get_parameters
      parameters.delete(:timeout_in_minutes)
      stack = cloudformation_client.update_stack(parameters)
      wait_until_stack_update_completed(stack.stack_id)
      find_existing
    end

    def self.find_or_create
      vpc = find_existing
      return vpc if vpc

      if requested_vpc_has_conflicts_with_existing_one?
        raise VpcConflictsWithAnother
      end
      stack = cloudformation_client.create_stack(get_parameters)

      wait_until_stack_build_completed(stack.stack_id)

      find_existing
    end

    def self.find_existing
      all.find do |vpc|
        (vpc.cidr_block == vpc_config[:cidr_block]) &&
          (extract_name_from(vpc) == vpc_name)
      end
    end

    private

    def self.get_parameters
      parameters = [
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
        {
          parameter_key: 'DbCIDRBlock',
          parameter_value: vpc_config[:db_cidr_block]
        },
        {
          parameter_key: 'SNSTopicName',
          parameter_value: topic_name
        },
        {
          parameter_key: 'PrimaryAZ',
          parameter_value: vpc_config[:primary_az]
        },
        {
          parameter_key: 'SecondaryAZ',
          parameter_value: vpc_config[:secondary_az]
        }
      ]

      if supports_efs?
        parameters << {
          parameter_key: 'CreateEFS',
          parameter_value: build_efs_resources?
        }
      end

      {
        stack_name: vpc_name,
        template_body: File.read(get_template_path),
        parameters: parameters,
        timeout_in_minutes: 15,
        tags: [
          {
            key: 'opsworks:stack',
            value: stack_config[:name]
          }
        ].concat(stack_custom_tags)
      }
    end

    def self.get_template_path
      if supports_efs?
        './templates/OpsWorksinVPCWithEFS.template'
      else
        './templates/OpsWorksinVPC.template'
      end
    end

    def self.build_efs_resources?
      if is_using_efs_storage?
        'yes'
      else
        'no'
      end
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

    def self.create_custom_tags
      if stack_custom_tags.empty?
        return
      end

      vpc = find_existing
      vpc.create_tags({
          dry_run: false,
          tags: stack_custom_tags
      })
    end
  end
end
