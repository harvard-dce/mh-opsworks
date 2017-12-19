require 'pry'
module Cluster
  class Analytics < Base
    include Cluster::Waiters

    def self.all
      stacks = []
      cloudformation_client.describe_stacks.inject([]){ |memo, page| memo + page.stacks }.each do |stack|
        stacks << construct_instance(stack.stack_id)
      end
      stacks
    end

    def self.delete
      stack = find_existing

      if stack
        cloudformation_client.delete_stack(
            stack_name: stack.stack_id
        )
        wait_until_analytics_stack_delete_completed(stack.stack_id)
      end
    end

    def self.find_or_create
      stack = find_existing
      return stack if stack

      stack = cloudformation_client.create_stack(get_parameters)

      wait_until_analytics_stack_build_completed(stack.stack_id)

      find_existing
    end

    def self.find_existing
      all.find do |stack|
        stack.stack_name == analytics_stack_name
      end
    end

    def self.update
      parameters = get_parameters
      parameters.delete(:timeout_in_minutes)
      stack = cloudformation_client.update_stack(parameters)
      wait_until_analytics_stack_update_completed(stack.stack_id)
      find_existing
    end

    def self.construct_instance(stack_id)
      Aws::CloudFormation::Stack.new(stack_id, client: cloudformation_client)
    end

    private

    def self.get_parameters

      template_params = [
          {
              parameter_key: 'OpsworksVPCStackName',
              parameter_value: vpc_name
          },
          {
              parameter_key: 'ESInstanceCount',
              parameter_value: analytics_config[:es_instance_count]
          },
          {
              parameter_key: 'ESInstanceType',
              parameter_value: analytics_config[:es_instance_type]
          }
      ]

      {
        stack_name: analytics_stack_name,
        template_body: get_cf_template,
        parameters: template_params,
        timeout_in_minutes: 60,
        capabilities: ["CAPABILITY_NAMED_IAM"],
        tags: [
          {
            key: 'opsworks:stack',
            value: stack_config[:name]
          }
        ].concat(stack_custom_tags)
      }
    end

    def self.get_cf_template
      erb = Erubis::Eruby.new(File.read('./templates/analytics.template.erb'))
      attributes = {}
      erb.result(attributes)
    end
  end
end
