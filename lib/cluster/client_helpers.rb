module Cluster
  module ClientHelpers
    module ClassMethods

      def efs_client
        Aws::EFS::Client.new(
          region: config.parsed[:region],
          credentials: config.credentials
        )
      end

      def sns_client
        Aws::SNS::Client.new(
          region: config.parsed[:region],
          credentials: config.credentials
        )
      end

      def cloudwatch_client
        Aws::CloudWatch::Client.new(
          region: config.parsed[:region],
          credentials: config.credentials
        )
      end

      def s3_client
        Aws::S3::Client.new(
          region: 'us-east-1',
          credentials: config.credentials
        )
      end

      def cloudformation_client
        Aws::CloudFormation::Client.new(
          region: config.parsed[:region],
          credentials: config.credentials
        )
      end

      def iam_client
        Aws::IAM::Client.new(
          region: config.parsed[:region],
          credentials: config.credentials
        )
      end

      def ec2_client
        Aws::EC2::Client.new(
          region: config.parsed[:region],
          credentials: config.credentials
        )
      end

      def opsworks_client
        Aws::OpsWorks::Client.new(
          region: 'us-east-1',
          credentials: config.credentials
        )
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
