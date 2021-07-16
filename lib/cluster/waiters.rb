module Cluster
  module Waiters
    module ClassMethods

      def wait_until_rds_instance_available(db_instance_identifier)
        puts "Waiting for #{db_instance_identifier} to be available..."
        rds_client.wait_until(
          :db_instance_available, db_instance_identifier: db_instance_identifier
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " #{db_instance_identifier} is available!"
      end

      def wait_for_rds_instance_modification(db_instance_identifier)
        puts "Waiting for RDS instance modification to complete..."
        sleep(30)
        rds_client.wait_until(
          :db_instance_available, db_instance_identifier: db_instance_identifier
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
      end

      def wait_until_rds_instance_deleted(db_instance_identifier)
        puts "Waiting for RDS instance to be deleted..."
        rds_client.wait_until(
          :db_instance_deleted, db_instance_identifier: db_instance_identifier
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " RDS instance is deleted!"
      end

      # Note that rds cluster waiters use a custom block as there's no built-in waiters
      # for db cluster states
      def wait_until_rds_cluster_available(rds_cluster)
        puts "Waiting for RDS cluster to be available..."
        rds_cluster.wait_until(**custom_waiter_params) { |cluster|
          cluster.status == "available"
        }
        puts "RDS cluster is available"
      end

      def wait_until_rds_cluster_stopped(rds_cluster)
        puts "Waiting for RDS cluster to be stopped..."
        rds_cluster.wait_until(**custom_waiter_params) { |cluster|
          cluster.status == "stopped"
        }
        puts "RDS cluster is stopped"
      end

      def wait_until_deployment_completed(deployment_id)
        print "Waiting for deployment, command, or recipe to execute successfully: "
        opsworks_client.wait_until(
          :deployment_successful, deployment_ids: [deployment_id]
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " done!"
      end

      def wait_until_stack_update_completed(cfn_stack_id)
        cfn_stack_name = cfn_stack_name_from_id(cfn_stack_id)
        print "Waiting for cloudformation infrastructure to be updated for #{cfn_stack_name}... "
        cloudformation_client.wait_until(
          :stack_update_complete, stack_name: cfn_stack_id
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " done!"
      end

      def wait_until_stack_build_completed(cfn_stack_id)
        cfn_stack_name = cfn_stack_name_from_id(cfn_stack_id)
        print "Waiting for cloudformation infrastructure to be built for #{cfn_stack_name}... "
        cloudformation_client.wait_until(
          :stack_create_complete, stack_name: cfn_stack_id
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " done!"
      end

      def wait_until_stack_delete_completed(cfn_stack_id)
        cfn_stack_name = cfn_stack_name_from_id(cfn_stack_id)
        print "Waiting for cloudformation infrastructure to be deleted for #{cfn_stack_name}... "
        cloudformation_client.wait_until(
          :stack_delete_complete, stack_name: cfn_stack_id
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " done!"
      end

      def wait_until_app_exists(app_id)
        print "Waiting for app to exist: #{app_id}: "
          opsworks_client.wait_until(:app_exists, app_ids: [app_id]) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end
        puts " done!"

        yield if block_given?
      end

      def wait_until_opsworks_instances_started(instance_ids = [])
        print "Ensuring #{instance_ids.length} instances are started: "
        opsworks_client.wait_until(
          :instance_online, instance_ids: instance_ids
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end

        puts " done!"
        yield if block_given?
      end

      def wait_until_all_configure_events_complete
        instance_ids = Cluster::Instances.online.map(&:instance_id)
        print "Waiting for configuration events to propagate across the entire cluster: "

        sleep 30
        loop do
          incomplete_configures = []
          instance_ids.each do |instance_id|
            incomplete_configures << opsworks_client.describe_commands(instance_id: instance_id).commands.find_all do |c|
              c.type == 'configure' && (c.status == 'pending') && (Time.now() - Time.parse(c.created_at) < 600)
            end
          end
          print '.'
          break if incomplete_configures.flatten.compact.empty?
          sleep 5
        end
        puts " done!"
      end

      def wait_until_opsworks_instances_stopped(instance_ids = [])
        print "Ensuring #{instance_ids.length} instances are stopped: "
        opsworks_client.wait_until(
          :instance_stopped, instance_ids: instance_ids
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end

        puts " done!"
        yield if block_given?
      end

      def wait_until_user_exists(user_name)
        print "Checking if user #{user_name} exists: "
        iam_client.wait_until(:user_exists, user_name: user_name) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end

        puts " done!"
        yield if block_given?
      end

      def wait_until_instance_profile_exists(instance_profile_name)
        print "Checking if instance profile #{instance_profile_name} exists: "
        iam_client.wait_until(
          :instance_profile_exists,
          instance_profile_name: instance_profile_name
        ) do |w|
          ::Cluster::Instance.apply_wait_options(w)
        end

        puts " done!"
        yield if block_given?
      end

      def apply_wait_options(w)
        w.tap do |w|
          w.max_attempts = 60
          w.delay = 0
          w.before_wait do |attempts, response|0
            sleep((attempts + 2) ** 2)
            print '.'
          end
        end
      end

      # I'm not good enough at ruby to figure out a more elegant way to pass a custom
      # waiter {...} block but also wrap it with our waiter params so here I just
      # create a throwaway waiter object to get the correct param values to use
      def custom_waiter_params
        throwaway_waiter = apply_wait_options(Aws::Waiters::Waiter.new())
        throwaway_waiter.instance_variables.each_with_object({}) {|var, hash|
          hash[var.to_s.delete("@").to_sym] = throwaway_waiter.instance_variable_get(var)
        }
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
