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
      begin
        stack = cloudformation_client.update_stack(parameters)
        wait_until_stack_update_completed(stack.stack_id)
      rescue => e
        puts e.message
        unless e.message.start_with? "No updates"
          raise
        end
      end
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

    def self.create_flowlog
      vpc = find_existing
      service_role = ServiceRole.find_or_create
      begin
        cwlogs_client.create_log_group({
          log_group_name: "#{stack_shortname}-vpc-flowlogs"
        })
      rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
      end
      cwlogs_client.put_retention_policy({
          log_group_name: "#{stack_shortname}-vpc-flowlogs",
          retention_in_days: 90
      })
      ec2_client.create_flow_logs({
          deliver_logs_permission_arn: service_role.arn,
          log_group_name: "#{stack_shortname}-vpc-flowlogs",
          resource_ids: [vpc.vpc_id],
          resource_type: "VPC",
          traffic_type: "ALL"
      })
    end

    def self.get_subnet_cidr_blocks(idx, len)
      ip = NetAddr::IPv4Net.parse(vpc_config[:cidr_block])
      (idx..(idx + len - 1)).map { |i| ip.nth_subnet(27, i).to_s }
    end

    def self.get_public_subnet_cidr_blocks
      get_subnet_cidr_blocks(0, 2)
    end

    def self.get_private_subnet_cidr_blocks
      get_subnet_cidr_blocks(2, 4)
    end


    private

    def self.get_parameters
      parameters = [
        {
          parameter_key: 'CIDRBlock',
          parameter_value: vpc_config[:cidr_block]
        },
        {
          parameter_key: 'PublicCIDRBlocks',
          parameter_value: get_public_subnet_cidr_blocks.join(',')
        },
        {
          parameter_key: 'PrivateCIDRBlocks',
          parameter_value: get_private_subnet_cidr_blocks.join(',')
        },
        {
          parameter_key: 'PrimaryAZ',
          parameter_value: primary_az
        },
        {
          parameter_key: 'SecondaryAZ',
          parameter_value: secondary_az
        },
        {
          parameter_key: "PrivateSubnetAZs",
          parameter_value: subnet_azs
        }
      ]

      {
        stack_name: vpc_name,
        template_body: get_cf_template,
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

    def self.get_cf_template
      erb = Erubis::Eruby.new(File.read('./templates/OpsWorksinVPC.template.erb'))
      attributes = {
          vpn_ips: stack_secrets[:vpn_ips],
          ca_ips: stack_secrets[:ca_ips],
          ibm_watson_ips: ibm_watson_config.fetch(:ips, []),
          nfs_server_host: storage_config.fetch(:nfs_server_host, nil)
      }
      erb.result(attributes)
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
