module Cluster
  class User < Base
    def self.all
      iam_users = IAMUser.all
      stack_id = Stack.find_or_create.stack_id

      opsworks_client.describe_permissions(stack_id: stack_id).permissions
    end

    def self.reset_stack_user_permissions_for(stack_id)
      opsworks_permissions = opsworks_client.describe_permissions(
        stack_id: stack_id
      ).permissions

      syncer = PermissionsSyncer.new(
        configured_users: stack_config[:users],
        iam_users: IAMUser.all,
        opsworks_permissions: opsworks_permissions,
        stack_id: stack_id
      )
      syncer.remove_unconfigured_user_profiles
      syncer.create_missing_users
      syncer.create_missing_opsworks_user_profiles
      syncer.set_user_permissions_from_config
    end
  end
end
