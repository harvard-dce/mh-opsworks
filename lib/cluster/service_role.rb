module Cluster
  class ServiceRole < Base
    def self.all
      all_roles.find_all do |role|
        role.assume_role_policy_document.match(/opsworks/)
      end
    end

    # A ServiceRole defines the rights a service wants in relation to other aws resources.
    def self.find_or_create
      if ! exists?
        # TODO: wait semantics
        iam_client.create_role(
          role_name: service_role_name,
          assume_role_policy_document: assume_role_policy_document
        )
        # TODO: wait semantics
        iam_client.put_role_policy(
          role_name: service_role_name,
          policy_name: "#{service_role_name}-policy",
          policy_document: service_role_policy_document
        )
      end
      construct_instance(service_role_name)
    end

    private

    def self.construct_instance(name)
      Aws::IAM::Role.new(name, client: iam_client)
    end

    def self.exists?
      all.find do |role|
        role.role_name == service_role_name
      end
    end

    def self.all_roles
      iam_client.list_roles.roles.map do |role|
        construct_instance(role.role_name)
      end
    end
  end
end
