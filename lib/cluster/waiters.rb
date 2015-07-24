module Cluster
  module Waiters
    module ClassMethods
      def wait_until_stack_build_completed(cfn_stack_id)
        cloudformation_client.wait_until(
          :stack_create_complete, stack_name: cfn_stack_id
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Waiting for vpc infrastructure to be built for #{vpc_name}, attempt ##{attempts}"
          end
        end
      end

      def wait_until_stack_delete_completed(cfn_stack_id)
        cloudformation_client.wait_until(
          :stack_delete_complete, stack_name: cfn_stack_id
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Waiting for vpc infrastructure to be deleted for #{vpc_name}, attempt ##{attempts}"
          end
        end
      end

      def wait_until_app_exists(app_id)
        opsworks_client.wait_until(
          :app_exists, app_ids: [app_id]
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Waiting for app to exist: #{app_id}, attempt ##{attempts}"
          end
        end

        yield if block_given?
      end

      def wait_until_opsworks_instances_started(instance_ids = [])
        opsworks_client.wait_until(
          :instance_online, instance_ids: instance_ids
        ) do |w|
          w.max_attempts = 150
          w.delay = 20
          w.before_wait do |attempts, response|
            puts "Starting instances #{instance_ids.join(', ')}, attempt ##{attempts}"
          end
        end

        yield if block_given?
      end

      def wait_until_opsworks_instances_stopped(instance_ids = [])
        opsworks_client.wait_until(
          :instance_stopped, instance_ids: instance_ids
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Stopping instance #{instance_ids.join(', ')}, attempt ##{attempts}"
          end
        end

        yield if block_given?
      end

      def wait_until_user_exists(user_name)
        iam_client.wait_until(
          :user_exists,
          user_name: user_name
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Checking if user #{user_name} exists, attempt: ##{attempts}"
          end
        end

        yield if block_given?
      end

      def wait_until_instance_profile_exists(instance_profile_name)
        iam_client.wait_until(
          :instance_profile_exists,
          instance_profile_name: instance_profile_name
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Checking if instance profile #{instance_profile_name} exists, attempt: ##{attempts}"
          end
        end

        yield if block_given?
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
