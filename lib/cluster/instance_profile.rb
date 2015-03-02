module Cluster
  class InstanceProfile < Base
    include Cluster::Waiters

    def self.all
      iam_client.list_instance_profiles.instance_profiles.map do |metadata|
        construct_instance(metadata.instance_profile_name)
      end
    end

    def self.delete
      instance_profile = find_instance_profile
      if instance_profile
        instance_profile_client = construct_instance(instance_profile.instance_profile_name)
        instance_profile_client.roles.each do |role|
          iam_client.remove_role_from_instance_profile(
            instance_profile_name: instance_profile_client.instance_profile_name,
            role_name: role.role_name
          )
        end
        instance_profile_client.delete

        delete_instance_profile_role(instance_profile_name)
      end
    end

    def self.find_or_create
      if ! exists?
        service_role = ServiceRole.find_or_create

        when_instance_profile_available(instance_profile_name) do
          iam_client.create_role(
            role_name: instance_profile_name,
            assume_role_policy_document: instance_profile_policy_document
          )

          iam_client.create_instance_profile(
            instance_profile_name: instance_profile_name
          )
          iam_client.add_role_to_instance_profile(
            role_name: service_role.role_name,
            instance_profile_name: instance_profile_name
          )
        end
      end
      construct_instance(instance_profile_name)
    end

    private

    def self.delete_instance_profile_role(instance_profile_name)
      instance_profile_role_client = Aws::IAM::Role.new(
        instance_profile_name,
        client: iam_client
      )
      instance_profile_role_client.policies.map(&:delete)
      instance_profile_role_client.delete
    end

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
