module Cluster
  module ConfigChecks
    class NoSshUsers < StandardError; end
    class TemplateUserNotRemoved < StandardError; end

    class RealUsers < Base
      def self.sane?
        users = stack_config[:users]

        valid_users = users.find_all do |user|
          user[:user_name] != 'FILL_ME_IN'
        end

        users.each do |user|
          if user[:user_name] == 'FILL_ME_IN'
            raise TemplateUserNotRemoved.new(
              'Please remove the templatted user in your cluster config.'
            )
          end
        end

        if ! valid_users.any?
          raise NoSshUsers.new(
            'Please edit the "users" section of your cluster config to add a valid user. This will allow you to ssh to your cluster'
          )
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::RealUsers)
