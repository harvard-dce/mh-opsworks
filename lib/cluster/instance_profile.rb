module Cluster
  class InstanceProfile < Base
    def self.all
      iam_client.list_instance_profiles.instance_profiles.map do |metadata|
        construct_instance(metadata.instance_profile_name)
      end
    end

    def self.delete
      instance_profile = find_instance_profile
      if instance_profile
        construct_instance(instance_profile.instance_profile_name).delete
      end
    end

    def self.find_or_create
      if ! exists?
        service_role = ServiceRole.find_or_create
        # TODO: wait semantics
        iam_client.create_instance_profile(
          instance_profile_name: instance_profile_name
        )
        # TODO: wait semantics
        iam_client.put_role_policy(
          role_name: instance_profile_name,
          policy_name: "#{instance_profile_name}-policy",
          policy_document: instance_profile_policy_document
        )
        # TODO: wait semantics
        iam_client.add_role_to_instance_profile(
          role_name: service_role.role_name,
          instance_profile_name: instance_profile_name
        )
      end
      construct_instance(instance_profile_name)
    end

    private

    def self.construct_instance(name)
      Aws::IAM::InstanceProfile.new(name, client: iam_client)
    end

    def self.find_instance_profile
      iam_client.list_instance_profiles.instance_profiles.find do |instance_profile|
        instance_profile.instance_profile_name == instance_profile_name
      end
    end

    def self.exists?
      find_instance_profile
    end
  end
end
