module Cluster
  class Stack < Base
    def self.all
      stacks = []
      opsworks_client.describe_stacks.each do |page|
        page.stacks.each do |stack|
          stacks << stack
        end
      end
      stacks
    end

    def self.find_or_create
      vpc = VPC.find_or_create

      stack = find_stack_in(vpc)
      return stack if stack

      parameters = {
        name: stack_config[:name],
        region: root_config[:region],
        vpc_id: vpc.vpc_id,

        service_role_arn: '',
        default_instance_profile_arn: ''
      }
      stack = opsworks_client.create_stack(
        parameters
      )
      stack
    end

    private

    def self.find_stack_in(vpc)
      all.find do |stack|
        (stack.name == stack_config[:name]) &&
          (stack.vpc_id == vpc.vpc_id)
      end
    end

    def self.root_config
      config.json
    end

    def self.stack_config
      config.json[:stack]
    end
  end
end
