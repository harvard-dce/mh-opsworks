module Cluster
  class PermissionsSyncer < Base
    attr_reader :configured_users,
      :iam_users,
      :opsworks_permissions,
      :stack_id,
      :arns_by_username

    def initialize(configured_users: nil, iam_users: nil, opsworks_permissions: nil, stack_id: nil)
      @configured_users = configured_users
      @iam_users = iam_users
      @opsworks_permissions = opsworks_permissions
      @stack_id = stack_id

      @arns_by_username ||= iam_users.reduce({}) do |memo, user|
        memo[user.user_name] = user.arn
        memo
      end
    end

    def deny_privileges_for_unconfigured_users
      opsworks_permissions.each do |permission|
        if user_has_no_configuration?(permission.iam_user_arn) &&
          is_not_me?(permission.iam_user_arn)
          self.class.opsworks_client.set_permission(
            iam_user_arn: permission.iam_user_arn,
            stack_id: stack_id,
            level: 'deny'
          )
        end
      end
    end

    def create_missing_users
      configured_users.each do |configured_user|
        if ! user_name_exists_in_iam?(configured_user[:user_name])
          new_iam_user = self.class.iam_client.create_user(
            user_name: configured_user[:user_name]
          )
          @iam_users << new_iam_user.user
        end
      end
    end

    def sync_opsworks_user_profiles
      user_profiles = self.class.opsworks_client.describe_user_profiles.inject([]){ |memo, page| memo + page.user_profiles }
      configured_users.each do |configured_user|
        user_name = configured_user[:user_name]
        ssh_key = configured_user.fetch(:ssh_public_key, '')

        user_profile = user_profiles.find { |user_profile| user_profile.name == user_name }
        if ! user_profile
          create_user_profile(arns_by_username[user_name], ssh_key)
        else
          if user_profile.ssh_public_key.nil? && (ssh_key != '')
            update_ssh_key_on_user_profile(user_profile.iam_user_arn, ssh_key)
          end
        end
      end
    end

    def set_user_permissions_from_config
      configured_users.each do |user|
        arn = arns_by_username[user[:user_name]]
        if is_not_me?(arn)
          self.class.opsworks_client.set_permission(
            iam_user_arn: arn,
            stack_id: stack_id,
            level: user[:level],
            allow_ssh: user[:allow_ssh],
            allow_sudo: user[:allow_sudo]
          )
        end
      end
    end

    private

    def create_user_profile(user_arn, ssh_key)
      self.class.opsworks_client.create_user_profile(
        iam_user_arn: user_arn,
        ssh_public_key: ssh_key,
        allow_self_management: true
      )
    end

    def update_ssh_key_on_user_profile(user_arn, ssh_key)
      self.class.opsworks_client.update_user_profile(
        iam_user_arn: user_arn,
        ssh_public_key: ssh_key,
        allow_self_management: true
      )
    end

    def is_not_me?(arn)
      self.class.iam_client.get_user.user.arn != arn
    end

    def user_name_exists_in_iam?(user_name)
      iam_users.find { |iam_user| iam_user.user_name == user_name }
    end

    def user_has_no_configuration?(arn)
      user_name = iam_users.find{|u| u.arn == arn }.user_name
      ! configured_users.find { |u| u[:user_name] == user_name }
    end
  end
end
