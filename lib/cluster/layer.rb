module Cluster
  class Layer < Base
    attr_reader :stack, :params

    def initialize(stack, params)
      @stack = stack
      @params = params
    end

    def create
      custom_security_group_ids = []
      if private_layer?
        custom_security_group_ids << get_security_group_for_private_layer
      end

      layer_parameters = {
        stack_id: stack.stack_id,
        type: params.fetch(:type, 'custom'),
        enable_auto_healing: params.fetch(:enable_auto_healing, false),
        name: params[:name],
        attributes: layer_attributes,
        shortname: params[:shortname],
        auto_assign_elastic_ips: params.fetch(:auto_assign_elastic_ips, false),
        auto_assign_public_ips: params.fetch(:auto_assign_public_ips, false),
        custom_recipes: params.fetch(:custom_recipes, {}),
        volume_configurations: params.fetch(:volume_configurations, {}),
        use_ebs_optimized_instances: params.fetch(:use_ebs_optimized_instances, false),
        custom_security_group_ids: custom_security_group_ids
      }
      layer = opsworks_client.create_layer(layer_parameters)
      construct_instance(layer.layer_id)
    end

    def get_security_group_for_private_layer
      private_network_sg = ec2_client.describe_security_groups.inject([]){ |memo, page| memo + page.security_groups }.find do |group|
        # This is tightly coupled to the implementation in templates/OpsWorksinVPC.template
        group.group_name.match(/#{vpc_name}-OpsWorksSecurityGroup/)
      end
      private_network_sg.group_id
    end

    def private_layer?
      params.fetch(:auto_assign_public_ips, false) == false &&
        params.fetch(:auto_assign_elastic_ips, false) == false
    end

    def self.find_or_create(params)
      layer = find_existing_by_name(params[:name])
      return construct_instance(layer.layer_id) if layer

      layer = new(Stack.find_or_create, params)
      layer.create
    end

    def self.find_existing_by_name(name)
      stack = Stack.with_existing_stack
      stack.layers.find do |layer|
        layer.name == name
      end
    end

    private

    def layer_attributes
      self.class.config.parsed_secrets.fetch(
        %Q|#{params[:shortname]}-attributes|.to_sym, {}
      )
    end

    def opsworks_client
      self.class.opsworks_client
    end

    def ec2_client
      self.class.ec2_client
    end

    def vpc_name
      self.class.vpc_name
    end

    def self.construct_instance(layer_id)
      Aws::OpsWorks::Layer.new(layer_id, client: opsworks_client)
    end
  end
end
