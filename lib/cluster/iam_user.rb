module Cluster
  class IAMUser < Base
    def self.all
      iam_client.list_users.users.map do |user|
        Aws::IAM::User.new(user.user_name, client: iam_client)
      end
    end
  end
end
