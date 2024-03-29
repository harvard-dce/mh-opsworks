module Cluster
  class InstanceProfile < Base
    include Cluster::Waiters

    def self.all
      iam_client.list_instance_profiles.inject([]){ |memo, page| memo + page.instance_profiles }.map do |metadata|
        construct_instance(metadata.instance_profile_name)
      end
    end

    def self.delete
      instance_profile = find_instance_profile
      if instance_profile
        instance_profile.roles.each do |role|
          iam_client.remove_role_from_instance_profile(
            instance_profile_name: instance_profile.instance_profile_name,
            role_name: role.role_name
          )
        end
        instance_profile.delete

        delete_instance_profile_role(instance_profile_name)
      end
    end

    def self.find_or_create
      if ! exists?
        iam_client.create_role(
          role_name: instance_profile_name,
          assume_role_policy_document: instance_profile_assume_role_policy_document
        )
        iam_client.create_instance_profile(
          instance_profile_name: instance_profile_name
        )
        # This policy allows an instance to use other related AWS resources
        # without needing to have an access key or other local credentials.
        iam_client.put_role_policy(
          role_name: instance_profile_name,
          policy_name: "#{instance_profile_name}-policy",
          policy_document: instance_profile_policy_document
        )
        # this is necessary for the cloudwatch logs integration
        iam_client.attach_role_policy(
          role_name: instance_profile_name,
          policy_arn: "arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs"
        )
        iam_client.add_role_to_instance_profile(
          role_name: instance_profile_name,
          instance_profile_name: instance_profile_name
        )

        # This seems an adequate amount of time to wait for the
        # instance profile to propagate, unfortunately
        # I can't find a way to test for propagation.
        sleep 10
        wait_until_instance_profile_exists(instance_profile_name)
      end
      construct_instance(instance_profile_name)
    end

    private

    def self.delete_instance_profile_role(instance_profile_name)
      instance_profile_role_client = Aws::IAM::Role.new(
        instance_profile_name,
        client: iam_client
      )
      # this detatches any aws managed policies, e.g. access to cloudwatch logs
      instance_profile_role_client.attached_policies.each do |policy|
        instance_profile_role_client.detach_policy({
          policy_arn: policy.arn
        })
      end
      # this deletes any homebrew policies we've attached
      instance_profile_role_client.policies.map(&:delete)
      instance_profile_role_client.delete
    end

    def self.construct_instance(name)
      Aws::IAM::InstanceProfile.new(name, client: iam_client)
    end

    def self.find_instance_profile
      all.find do |instance_profile|
        instance_profile.instance_profile_name == instance_profile_name
      end
    end

    def self.exists?
      find_instance_profile
    end
  end
end
