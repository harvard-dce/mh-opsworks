module Cluster
  class ServiceRole < Base
    def self.all
      all_roles.find_all do |role|
        role.assume_role_policy_document.match(/opsworks/)
      end
    end

    def self.delete
      service_role = find_service_role
      if service_role
        service_role_client = construct_instance(service_role.name)
        service_role_client.policies.map(&:delete)
        service_role_client.delete
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

    def self.find_service_role
      all.find do |role|
        role.role_name == service_role_name
      end
    end

    def self.exists?
      find_service_role
    end

    def self.all_roles
      iam_client.list_roles.inject([]){ |memo, page| memo + page.roles }.map do |role|
        construct_instance(role.role_name)
      end
    end
  end
end
