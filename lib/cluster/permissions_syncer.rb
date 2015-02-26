module Cluster
  class PermissionsSyncer < Base
    attr_reader :configured_users,
      :iam_users,
      :opsworks_permissions,
      :stack_id,
      :arns_by_username

    def initialize(configured_users:, iam_users:, opsworks_permissions:, stack_id:)
      @configured_users = configured_users
      @iam_users = iam_users
      @opsworks_permissions = opsworks_permissions
      @stack_id = stack_id

      @arns_by_username ||= iam_users.reduce({}) do |memo, user|
        memo[user.user_name] = user.arn
        memo
      end
    end

    def remove_unconfigured_user_profiles
      opsworks_permissions.each do |permission|
        if user_has_no_configuration?(permission.iam_user_arn) &&
          is_not_me?(permission.iam_user_arn)
          # TODO  - wait semantics
          self.class.opsworks_client.delete_user_profile(
            iam_user_arn: permission.iam_user_arn,
          )
        end
      end
    end

    def create_missing_users
      configured_users.each do |configured_user|
        if ! user_name_exists_in_iam?(configured_user[:user_name])
          # TODO - wait semantics
          new_iam_user = self.class.iam_client.create_user(
            user_name: configured_user[:user_name]
          )
          @iam_users << new_iam_user.user
        end
      end
    end

    def create_missing_opsworks_user_profiles
      user_profiles = self.class.opsworks_client.describe_user_profiles.user_profiles
      configured_users.each do |configured_user|
        user_name = configured_user[:user_name]
        if ! user_profiles.find { |user_profile| user_profile.name == user_name }
          # TODO  - wait semantics
          self.class.opsworks_client.create_user_profile(
            iam_user_arn: arns_by_username[user_name]
          )
        end
      end
    end

    def set_user_permissions_from_config
      configured_users.each do |user|
        arn = arns_by_username[user[:user_name]]
        if is_not_me?(arn)
          # TODO  - wait semantics
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
