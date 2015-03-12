require 'pry'
module Cluster
  class VPC < Base
    include Cluster::Waiters

    def self.all
      vpcs = []
      ec2_client.describe_vpcs.each do |page|
        page.vpcs.each do |vpc|
          vpcs << construct_instance(vpc.vpc_id)
        end
      end
      vpcs
    end

    def self.delete
      vpc = find_existing
      if vpc
        vpc_client = construct_instance(vpc.vpc_id)
        vpc_client.internet_gateways.each do |internet_gateway|
          vpc_client.detach_internet_gateway(
            internet_gateway_id: internet_gateway.internet_gateway_id
          )
          ec2_client.delete_internet_gateway(
            internet_gateway_id: internet_gateway.internet_gateway_id
          )
        end
        sub_resources.each do |method|
          vpc_client.send(method).map(&:delete)
        end
        delete_security_groups(vpc_client)
        vpc_client.delete
      end
    end

    def self.find_or_create
      vpc = find_existing
      if ! vpc
        if requested_vpc_has_conflicts_with_existing_one?
          raise VpcConflictsWithAnother
        end
        vpc = ec2_client.create_vpc(
          cidr_block: vpc_config[:cidr_block]
        ).first.vpc

        when_vpc_available(vpc.vpc_id) do
          construct_instance(vpc.vpc_id).tap do |vpc_instance|
            enable_dns_options(vpc_instance)
            create_and_associate_internet_gateway_for(vpc_instance)
            create_vpc_tags(vpc_instance)
            create_subnets(vpc_instance)
          end
        end
      end

      construct_instance(vpc.vpc_id)
    end

    def self.find_existing
      all.find do |vpc|
        (vpc.cidr_block == vpc_config[:cidr_block]) &&
          (extract_name_from(vpc) == vpc_config[:name])
      end
    end

    private

    def self.create_and_associate_internet_gateway_for(vpc_instance)
      gateway = ec2_client.create_internet_gateway.internet_gateway
      vpc_instance.attach_internet_gateway(internet_gateway_id: gateway.internet_gateway_id)
      route_table = vpc_instance.route_tables.first
      ec2_client.create_route(
        route_table_id: route_table.route_table_id,
        destination_cidr_block: '0.0.0.0/0',
        gateway_id: gateway.internet_gateway_id
      )
    end

    def self.enable_dns_options(vpc_instance)
      %i|enable_dns_support enable_dns_hostnames|.each do |attribute|
        vpc_instance.modify_attribute(
          attribute => { value: true }
        )
      end
    end

    def self.sub_resources
      %i|subnets network_interfaces requested_vpc_peering_connections|
    end

    def self.delete_security_groups(vpc_client)
      begin
        vpc_client.security_groups.reject{|sg| sg.group_name == 'default'}.each do |security_group|
          security_group.delete
        end
      rescue Aws::EC2::Errors::InvalidGroupNotFound => e
        puts 'ignoring Aws::EC2::Errors::InvalidGroupNotFound error'
      end
    end

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

    def self.extract_name_from(vpc)
      name_tag = vpc.tags.find { |t| t.key == 'Name' }
      if name_tag
        name_tag.value
      end
    end
  end
end
