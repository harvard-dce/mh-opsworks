module Cluster
  class Layer < Base
    attr_reader :stack, :params

    def initialize(stack, params)
      @stack = stack
      @params = params
    end

    def create
      layer_parameters = {
        stack_id: stack.stack_id,
        type: params.fetch(:type, 'custom'),
        enable_auto_healing: params.fetch(:enable_auto_healing, false),
        name: params[:name],
        attributes: params.fetch(:attributes, {}),
        shortname: params[:shortname],
        auto_assign_elastic_ips: params.fetch(:auto_assign_elastic_ips, false),
        auto_assign_public_ips: params.fetch(:auto_assign_public_ips, false),
        custom_recipes: params.fetch(:custom_recipes, {}),
        volume_configurations: params.fetch(:volume_configurations, {}),
        use_ebs_optimized_instances: params.fetch(:use_ebs_optimized_instances, false)
      }
      layer = opsworks_client.create_layer(layer_parameters)
      construct_instance(layer.layer_id)
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

    def opsworks_client
      self.class.opsworks_client
    end

    def self.construct_instance(layer_id)
      Aws::OpsWorks::Layer.new(layer_id, client: opsworks_client)
    end
  end
end
