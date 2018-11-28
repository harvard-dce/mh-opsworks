module Cluster
  class User < Base
    def self.all
      stack = Stack.with_existing_stack

      opsworks_client.describe_permissions(
        stack_id: stack.stack_id
      ).inject([]){ |memo, page| memo + page.permissions }
    end

    def self.reset_stack_user_permissions_for(stack_id)
      opsworks_permissions = all

      syncer = PermissionsSyncer.new(
        configured_users: stack_config[:users],
        iam_users: IAMUser.all,
        opsworks_permissions: opsworks_permissions,
        stack_id: stack_id
      )

      # checks each opsworks permission entry to see if there is a corresponding iam user entry
      # if there is not the opsworks permissions are set to read only. the intention is to disable
      # opsworks access when iam users are removed
      syncer.read_only_privileges_for_unconfigured_users

      # creates a stub iam user (if none exists) for each "users" entry in the cluster config's
      syncer.create_missing_users

      # for each "users" entry in the cluster config, ensures that a user profile exists in the
      # AWS account's top-level Opsworks User list
      syncer.sync_opsworks_user_profiles

      # updates the opsworks permissions for the stack based on "users" entries in the cluster config
      syncer.set_user_permissions_from_config
    end
  end
end
