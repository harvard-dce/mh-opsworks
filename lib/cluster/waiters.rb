module Cluster
  module Waiters
    module ClassMethods
      def wait_until_app_available(app_id)
        opsworks_client.wait_until(
          :app_available, app_ids: [app_id]
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Waiting for app to be available: #{app_id}, attempt ##{attempts}"
          end
        end

        yield if block_given?
      end

      def wait_until_opsworks_instances_started(instance_ids = [])
        opsworks_client.wait_until(
          :instances_online, instance_ids: instance_ids
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
          :instances_stopped, instance_ids: instance_ids
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Stopping instance #{instance_ids.join(', ')}, attempt ##{attempts}"
          end
        end

        yield if block_given?
      end

      def when_vpc_available(vpc_id)
        ec2_client.wait_until(:vpc_available, vpc_ids: [vpc_id]) do |w|
          w.before_wait do |attempts, response|
            puts "Checking if VPC available, attempt ##{attempts}"
          end
        end

        yield if block_given?
      end

      def wait_until_instance_profile_available(instance_profile_name)
        iam_client.wait_until(
          :instance_profile_available,
          instance_profile_name: instance_profile_name
        ) do |w|
          w.before_wait do |attempts, response|
            puts "Checking if instance profile #{instance_profile_name} available, attempt: ##{attempts}"
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
