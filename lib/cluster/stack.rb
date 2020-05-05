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

    def self.stop_all(stop_rds=true)
      with_existing_stack do |stack|
        puts 'turning on maintenance mode, stopping opencast on engage and workers. . . '
        Cluster::Deployment.execute_chef_recipes_on_layers(
          recipes: ['oc-opsworks-recipes::maintenance-mode-on', 'oc-opsworks-recipes::stop-opencast'],
          layers: ['Engage', 'Workers']
        )

        rds_stop = Concurrent::Future.execute {
          stop_rds and Cluster::RDS.stop
        }

        stop_all_in_layers(
          ['workers', 'admin', 'engage', 'monitoring-master']
        )
        stop_all_in_layers(['storage'])
        stop_all_other_instances

        begin
          rds_stop.value!
        rescue => e
          puts "Something went wrong stopping the rds cluster: #{rds_stop.reason}"
          puts e.backtrace
        end
      end
    end

    def self.start_all(num_workers)
      with_existing_stack do |stack|

        rds_start = Concurrent::Future.execute {
          Cluster::RDS.start
        }

        start_all_in_layers(['storage'])

        begin
          rds_start.value!
        rescue => e
          puts "Something went wrong starting the rds cluster: #{rds_start.reason}"
          puts e.backtrace
        end

        start_all_in_layers(['admin'])
        if num_workers.nil?
          start_all_in_layers(['workers', 'engage','monitoring-master'])
        else
          workers_start = Concurrent::Future.execute {
            start_some_in_layer('workers', num_workers)
          }
          start_all_in_layers(['engage','monitoring-master'])
          begin
            workers_start.value!
          rescue => e
            puts "Something went wrong starting the workers: #{workers_start.reason}"
            puts e.backtrace
          end
        end
        start_all_other_instances(include_workers = num_workers.nil?)
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

      stack_instance = construct_instance(stack.stack_id)

      stack_tags = stack_custom_tags.each_with_object({}) do |tag, memo|
        memo[tag[:key]] = tag[:value]
      end
      opsworks_client.tag_resource({
        resource_arn: stack_instance.arn,
        tags: stack_tags
      })

      stack_instance
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

    def self.start_all_other_instances(include_workers = true)
      instance_ids = Cluster::Instances.find_existing_always_on_instances.find_all do |instance|
        instance.status != 'online' && (include_workers || !instance.hostname.start_with?("worker"))
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

    def self.instance_ids_in_layers(shortnames=[])
      Cluster::Instances.find_manageable_instances_by_layer_shortname(
          shortnames
      ).find_all { |instance| instance.status != 'online' }.map(&:instance_id)
    end

    def self.start_all_in_layers(shortnames=[])
      instance_ids = instance_ids_in_layers(shortnames)
      if instance_ids.any?
        puts "Starting #{shortnames.join(', ')} instances"
        start_and_wait_for_instances(instance_ids)
      end
    end

    def self.start_some_in_layer(layer_shortname, num_instances)
      instance_ids = instance_ids_in_layers([layer_shortname])
      if instance_ids.any?
        puts "Starting #{num_instances} #{layer_shortname} instances"
        start_and_wait_for_instances(instance_ids.sample(num_instances))
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
      cookbook_source = stack_chef_config.fetch(:custom_cookbooks_source, {})

      if (cookbook_source[:type] == "s3") && (! cookbook_source.has_key? :url)
        cookbook_source[:url] = get_cookbook_source_s3_url(cookbook_source[:revision])
      end

      # remove any comments
      cookbook_source.delete(:_comment)

      instance_profile = InstanceProfile.find_or_create

      custom_json = stack_custom_json
      rds_cluster = Cluster::RDS.find_existing

      # IMPORTANT:
      # Here we override the stack's deployment information for the database
      # with the endpoint of the *cluster*. When the opsworks stack/app is
      # initialized it gets the endpoint for whichever db instance is currently
      # the "writer" (in a cluster with > 1 db instance, one is the writer and
      # the rest are "readers", i.e. replicas). We want our stack/app to talk
      # to the cluster's wrapper endpoint, so, in the case of a failover, we're
      # always connecting to the primary "writer" instance. This is a bit of a
      # hack/workaround, but was provided by AWS support as the accepted workaround
      # until opsworks more fully implements support for rds clusters.
      if rds_cluster
        custom_json[:deploy] = {
            app_config[:shortname].to_sym => {
                :database => {
                    :host => rds_cluster.endpoint,
                    :readonly_op_host => rds_cluster.reader_endpoint
                }
            }
        }
      end

      {
        name: stack_config[:name],
        region: root_config[:region],
        vpc_id: vpc.vpc_id,
        configuration_manager: {
          name: 'Chef',
          version: '11.10'
        },
        use_custom_cookbooks: true,
        custom_cookbooks_source: cookbook_source,
        chef_configuration: {
          manage_berkshelf: cookbook_source[:type] == "git",
          berkshelf_version: '3.2.0'
        },
        custom_json: json_encode(
          custom_json
        ),
        default_os: 'Ubuntu 14.04 LTS',
        service_role_arn: service_role.arn,
        default_instance_profile_arn: instance_profile.arn,
        default_subnet_id: vpc.subnets.first.id,
        default_root_device_type: stack_config.fetch(:default_root_device_type, 'ebs'),
        default_ssh_key_name: stack_config.fetch(:default_ssh_key_name, ''),
        use_opsworks_security_groups: false
      }
    end

    def self.construct_instance(stack_id)
      Aws::OpsWorks::Stack.new(stack_id, client: opsworks_client)
    end
  end
end
