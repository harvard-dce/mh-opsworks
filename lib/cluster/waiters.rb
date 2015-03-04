module Cluster
  module Waiters
    module ClassMethods
      def when_instance_stopped(instance_id)
        opsworks_client.wait_until(
          :instance_stopped, instance_ids: [instance_id]
        )

        yield
      end

      def when_vpc_available(vpc_id)
        ec2_client.wait_until(:vpc_available, vpc_ids: [vpc_id])

        yield
      end

      def when_instance_profile_available(instance_profile_name)
        iam_client.wait_until(
          :instance_profile_available,
          instance_profile_name: instance_profile_name
        )

        yield
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
