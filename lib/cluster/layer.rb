module Cluster
  class Layer < Base
    attr_reader :stack, :params

    def initialize(stack, params)
      @stack = stack
      @params = params
      @vpc = VPC.find_existing
      @sg_finder = SecurityGroupFinder.new(@vpc)
    end

    def construct_layer_parameters
      custom_security_group_ids = default_security_group_ids

      if private_layer?
        custom_security_group_ids << get_security_group_for_private_layer
      else
        custom_security_group_ids << get_security_group_for_public_layer
      end

      {
        stack_id: stack.stack_id,
        type: params.fetch(:type, 'custom'),
        enable_auto_healing: params.fetch(:enable_auto_healing, false),
        install_updates_on_boot: params.fetch(:install_updates_on_boot, false),
        name: params[:name],
        attributes: layer_attributes,
        shortname: params[:shortname],
        auto_assign_elastic_ips: params.fetch(:auto_assign_elastic_ips, false),
        auto_assign_public_ips: params.fetch(:auto_assign_public_ips, false),
        custom_recipes: params.fetch(:custom_recipes, {}),
        volume_configurations: params.fetch(:volume_configurations, {}),
        use_ebs_optimized_instances: params.fetch(:use_ebs_optimized_instances, false),
        custom_security_group_ids: custom_security_group_ids.compact,
        lifecycle_event_configuration: {
          shutdown: {
            execution_timeout: 60 * 2 # 2 minutes
          }
        }
      }
    end

    def create
      layer_parameters = construct_layer_parameters
      layer = opsworks_client.create_layer(layer_parameters)
      AutoScalingConfig.set_auto_scaling_params(layer.layer_id, params)
      construct_instance(layer.layer_id)
    end

    def default_security_group_ids
      [
        security_group_id_for("#{vpc_name}-InstancesAllowedToAccessEFS"),
        security_group_id_for("AWS-OpsWorks-Custom-Server")
      ]
    end

    def get_security_group_for_public_layer
      security_group_id_for("#{vpc_name}-DirectAccessToMatterhornDaemon")
    end

    def get_security_group_for_private_layer
      security_group_id_for("#{vpc_name}-OpsWorksSecurityGroup")
    end

    def private_layer?
      params.fetch(:auto_assign_public_ips, false) == false &&
        params.fetch(:auto_assign_elastic_ips, false) == false
    end

    def update
      layer = self.class.find_existing_by_name(stack, params[:name])
      if layer
        layer_parameters = construct_layer_parameters
        [:name, :shortname, :stack_id, :type].each do |to_remove|
          layer_parameters.delete(to_remove)
        end
        layer_parameters[:layer_id] = layer.layer_id
        opsworks_client.update_layer(layer_parameters)
        AutoScalingConfig.set_auto_scaling_params(layer.layer_id, params)
        construct_instance(layer.layer_id)
      else
        self.class.create_layer(stack, params)
      end
    end

    def self.update(stack, params)
      layer = new(stack, params)
      layer.update
    end

    def self.find_or_create(stack, params)
      layer = find_existing_by_name(stack, params[:name])
      return construct_instance(layer.layer_id) if layer

      create_layer(stack, params)
    end

    def self.find_existing_by_name(stack, name)
      stack.layers.find do |layer|
        layer.name == name
      end
    end

    private

    def self.create_layer(stack, params)
      layer = new(stack, params)
      layer.create
    end

    def security_group_id_for(name)
      @sg_finder.security_group_id_for(name)
    end

    def layer_attributes
      self.class.stack_custom_json.fetch(
        %Q|#{params[:shortname]}-attributes|.to_sym, {}
      )
    end

    def opsworks_client
      self.class.opsworks_client
    end

    def vpc_name
      self.class.vpc_name
    end

    def self.construct_instance(layer_id)
      Aws::OpsWorks::Layer.new(layer_id, client: opsworks_client)
    end
  end
end
