require 'pry'
module Cluster
  class InvalidPeerVpcId < StandardError; end
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
        delete_peering_connections
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

    def self.init_peering
      vpc = find_existing
      connections = peer_vpc_config.map { |peer_vpc_config|
        peer_vpc = construct_instance(peer_vpc_config[:id])
        unless peer_vpc.exists?
          raise InvalidPeerVpcId("VPC with id #{peer_vpc_config[:id]} does not exist!")
        end
        create_peer_connection(vpc, peer_vpc)
      }

      connections.each do |peer_connection|
        unless peer_connection.status.code == "active"
          accept_peer_connection(peer_connection)
        end
        create_peer_routes(peer_connection)
      end
    end

    def self.delete_peering_connections
      vpc = find_existing
      describe_params = {
        filters: [{
          name: "requester-vpc-info.vpc-id",
          values: [vpc.vpc_id]
        }]
      }
      ec2_client.describe_vpc_peering_connections(describe_params).inject([]) {
        |memo, page| memo + page.vpc_peering_connections
      }.each do |pc_info|
        peer_connection = Aws::EC2::VpcPeeringConnection.new(
          id: pc_info.vpc_peering_connection_id,
          client: ec2_client
        )
        peer_connection.delete
      end
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
          vpn_ips: stack_custom_json.fetch(:vpn_ips, []),
          ca_ips: stack_custom_json.fetch(:ca_ips, []),
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

    def self.create_peer_connection(vpc, peer_vpc)
      res = ec2_client.create_vpc_peering_connection({
        vpc_id: vpc.id,
        peer_vpc_id: peer_vpc.id
      })
      connection_id = res.vpc_peering_connection.vpc_peering_connection_id

      begin
        peer_vpc_name = peer_vpc.tags.find { |tag| tag.key == "Name" }.value
      rescue NoMethodError
        peer_vpc_name = peer_vpc.id
      end

      ec2_client.wait_until(
        :vpc_peering_connection_exists,
        vpc_peering_connection_ids: [connection_id]
      )

      ec2_client.create_tags({
        resources: [ connection_id ],
        tags: [
          { key: "Name",
            value: "#{stack_shortname}-to-#{peer_vpc_name}" },
          { key: "opsworks:stack",
            value: stack_shortname }
        ]
      })
      Aws::EC2::VpcPeeringConnection.new(
        id: connection_id,
        client: ec2_client
      )
    end

    def self.accept_peer_connection(peer_connection)
      begin
        # make sure peering connection is in the acceptable state
        peer_connection.wait_until(max_attempts: 5, delay: 5) { |connection|
          connection.status.code == "pending-acceptance"
        }
        peer_connection.accept
      rescue Aws::Waiters::Errors::WaiterFailed
        puts "VPC peering connection failed to enter 'pending-acceptance' state"
        puts "You may need to manually accept the connection via the web console"
      end
    end

    def self.create_peer_routes(peer_connection)
      accepter = construct_instance(peer_connection.accepter_vpc_info.vpc_id)
      requester = construct_instance(peer_connection.requester_vpc_info.vpc_id)
      # accepter route tables must have route to requester and vice versa
      accepter_routes = accepter.route_tables.map do |rt|
        { rt: rt, cidr: requester.cidr_block }
      end
      requester_routes = requester.route_tables.map do |rt|
        { rt: rt, cidr: accepter.cidr_block }
      end
      accepter_routes.concat(requester_routes).each do |route|
        begin
          route[:rt].create_route({
            destination_cidr_block: route[:cidr],
            vpc_peering_connection_id: peer_connection.id
            })
        rescue Aws::EC2::Errors::RouteAlreadyExists
          nil
        end
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
