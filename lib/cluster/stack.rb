module Cluster
  class Stack < Base
    # Returns a list of all stacks in the credentialled AWS account.
    # The list is composed of Aws::OpsWorks::Stack instances.
    def self.all
      stacks = []
      opsworks_client.describe_stacks.each do |page|
        page.stacks.each do |stack|
          stacks << construct_instance(stack.stack_id)
        end
      end
      stacks
    end

    def self.delete
      vpc = VPC.find_or_create
      stack = find_existing_in(vpc)
      if stack
        stack.delete
      end
    end

    # Returns a Aws::OpsWorks::Stack instance according to the active cluster
    # configuration If it does not exist, it creates it within your configured
    # VPC.
    def self.find_or_create
      vpc = VPC.find_or_create

      stack = find_existing_in(vpc)
      return construct_instance(stack.stack_id) if stack

      service_role = ServiceRole.find_or_create
      instance_profile = InstanceProfile.find_or_create

      parameters = {
        name: stack_config[:name],
        region: root_config[:region],
        vpc_id: vpc.vpc_id,

        service_role_arn: service_role.arn,
        default_instance_profile_arn: instance_profile.arn,
        default_subnet_id: vpc.subnets.first.id
      }

      stack = create_stack(parameters)

      User.reset_stack_user_permissions_for(stack.stack_id)

      construct_instance(stack.stack_id)
    end

    def self.find_existing_in(vpc)
      all.find do |stack|
        (stack.name == stack_config[:name]) &&
          (stack.vpc_id == vpc.vpc_id)
      end
    end

    private

    def self.create_stack(parameters)
      stack = nil
      loop do
        stack =
          begin
            opsworks_client.create_stack(
              parameters
            )
          rescue => e
            puts e.inspect
            sleep 10
            puts 'retrying stack creation'
            nil
          end
        break if stack != nil
      end
      stack
    end

    def self.construct_instance(stack_id)
      Aws::OpsWorks::Stack.new(stack_id, client: opsworks_client)
    end

  end
end
