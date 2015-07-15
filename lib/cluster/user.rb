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
      syncer.read_only_privileges_for_unconfigured_users
      syncer.create_missing_users
      syncer.sync_opsworks_user_profiles
      syncer.set_user_permissions_from_config
    end
  end
end
