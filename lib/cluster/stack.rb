module Cluster
  class Stack < Base
    include Waiters
    # Returns a list of all stacks in the credentialled AWS account.
    # The list is composed of Aws::OpsWorks::Stack instances.
    def self.all
      stacks = []
      opsworks_client.describe_stacks.inject([]){ |memo, page| memo + page.stacks }.each do |stack|
        stacks << construct_instance(stack.stack_id)
      end
      stacks
    end

    def self.update
      stack = find_existing
      if stack
        vpc = VPC.find_existing
        parameters = stack_parameters(vpc)
        [:region, :vpc_id, :name].each do |to_remove|
          parameters.delete(to_remove)
        end
        opsworks_client.update_stack(
          parameters.merge(stack_id: stack.stack_id)
        )
      end
    end

    def self.delete
      stack = find_existing
      if stack
        stack.delete
      end
    end

    def self.stop_all
      with_existing_stack do |stack|
        puts 'turning on maintenance mode, stopping matterhorn on engage and workers. . . '
        Cluster::Deployment.execute_chef_recipes_on_layers(
          recipes: ['mh-opsworks-recipes::maintenance-mode-on', 'mh-opsworks-recipes::stop-matterhorn'],
          layers: ['Engage', 'Workers']
        )
        stop_all_in_layers(
          ['workers', 'admin', 'engage', 'monitoring-master']
        )
        stop_all_in_layers(['storage'])
        stop_all_other_instances
      end
    end

    def self.start_all
      with_existing_stack do |stack|
        start_all_in_layers(['storage'])
        start_all_in_layers(['admin'])
        start_all_in_layers(['workers', 'engage','monitoring-master'])
        start_all_other_instances
      end
    end

    def self.find_existing
      vpc = VPC.find_existing
      find_existing_in(vpc)
    end

    def self.with_existing_stack
      stack = Cluster::Stack.find_existing
      raise Cluster::StackNotInitialized if ! stack

      yield stack if block_given?
      stack
    end

    # Returns a Aws::OpsWorks::Stack instance according to the active cluster
    # configuration If it does not exist, it creates it within your configured
    # VPC.
    def self.find_or_create
      vpc = VPC.find_or_create

      stack = find_existing_in(vpc)
      return construct_instance(stack.stack_id) if stack

      parameters = stack_parameters(vpc)

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

    def self.stop_all_other_instances
      instance_ids = Cluster::Instances.find_existing_always_on_instances.find_all do |instance|
        ! ['shutting_down', 'stopped', 'stopping', 'terminated', 'terminating'].include?(instance.status)
      end.map(&:instance_id)

      if instance_ids.any?
        puts "Stopping #{instance_ids.length} other instances"
        stop_and_wait_for_instances(instance_ids)
      end
    end

    def self.start_all_other_instances
      instance_ids = Cluster::Instances.find_existing_always_on_instances.find_all do |instance|
        instance.status != 'online'
      end.map(&:instance_id)
      if instance_ids.any?
        puts "Starting #{instance_ids.length} other instances"
        start_and_wait_for_instances(instance_ids)
      end
    end

    def self.start_and_wait_for_instances(instance_ids)
      instance_ids.each do |instance_id|
        opsworks_client.start_instance(instance_id: instance_id)
      end
      sleep 20
      wait_until_opsworks_instances_started(instance_ids)
      wait_until_all_configure_events_complete
    end

    def self.stop_and_wait_for_instances(instance_ids)
      instance_ids.each do |instance_id|
        opsworks_client.stop_instance(instance_id: instance_id)
      end
      sleep 20
      wait_until_opsworks_instances_stopped(instance_ids)
    end

    def self.stop_all_in_layers(shortnames=[])
      instance_ids = Cluster::Instances.find_manageable_instances_by_layer_shortname(
        shortnames
      ).map(&:instance_id)

      if instance_ids.any?
        puts "Stopping #{shortnames.join(', ')} instances"
        stop_and_wait_for_instances(instance_ids)
      end
    end

    def self.start_all_in_layers(shortnames=[])
      instance_ids = Cluster::Instances.find_manageable_instances_by_layer_shortname(
        shortnames
      ).find_all { |instance| instance.status != 'online' }.map(&:instance_id)

      if instance_ids.any?
        puts "Starting #{shortnames.join(', ')} instances"
        start_and_wait_for_instances(instance_ids)
      end
    end

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

    def self.stack_parameters(vpc)
      service_role = ServiceRole.find_or_create
      instance_profile = InstanceProfile.find_or_create
      {
        name: stack_config[:name],
        region: root_config[:region],
        vpc_id: vpc.vpc_id,
        configuration_manager: {
          name: 'Chef',
          version: '11.10'
        },
        use_custom_cookbooks: true,
        custom_cookbooks_source: stack_chef_config.fetch(:custom_cookbooks_source, {}),
        chef_configuration: {
          manage_berkshelf: true,
          berkshelf_version: '3.2.0'
        },
        custom_json: json_encode(
          stack_custom_json
        ),
        default_os: 'Ubuntu 14.04 LTS',
        service_role_arn: service_role.arn,
        default_instance_profile_arn: instance_profile.arn,
        default_subnet_id: vpc.subnets.first.id,
        default_root_device_type: stack_config.fetch(:default_root_device_type, 'ebs'),
        default_ssh_key_name: stack_config.fetch(:default_ssh_key_name, '')
      }
    end

    def self.construct_instance(stack_id)
      Aws::OpsWorks::Stack.new(stack_id, client: opsworks_client)
    end

    def self.find_volume_ids
      volume_ids = []
      stack = find_existing
      resp = opsworks_client.describe_volumes({stack_id: stack.stack_id})
      resp.volumes.each do |volume|
        volume_ids.push(volume.ec2_volume_id)
      end

      volume_ids
    end
  end
end
