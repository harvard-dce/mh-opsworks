module Cluster
  class Base
    require 'uri'
    require 'json'
    include ConfigurationHelpers
    include NamingHelpers
    include ClientHelpers

    def self.with_encoded_document
      JSON.pretty_generate(
        yield
      )
    end

    def self.json_encode(string)
      JSON.pretty_generate(string)
    end

    # Allows the construction of client interfaces at the instance level
    def construct_instance(instance_id)
      self.class.construct_instance(instance_id)
    end

    def self.storage_config
      stack_custom_json.fetch(:storage, {})
    end

    def self.supports_efs?
      root_config[:region] == 'us-west-2'
    end

    def self.is_using_efs_storage?
      storage_config[:subtype] == 'efs'
    end

    def self.external_storage?
      storage_config[:type] == 'external'
    end

    def self.instance_profile_policy_document
      with_encoded_document do
        {
          "Statement" =>  [
            {
              "Action" =>  [
                "s3:*",
                "sqs:*",
                "cloudwatch:*",
                "sns:CreateTopic",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:StartInstance",
                "opsworks:StopInstance",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeInstances",
                "rds:DescribeDBInstances"
              ],
              "Effect" => "Allow",
              "Resource" => [
                "*"
              ]
            }
          ]
        }
      end
    end

    def self.instance_profile_assume_role_policy_document
      with_encoded_document do
        {
          "Version" => "2008-10-17",
          "Statement" => [
            {
              "Sid" => "",
              "Effect" => "Allow",
              "Principal" => {
                "Service" => "ec2.amazonaws.com"
              },
              "Action" => "sts:AssumeRole"
            }
          ]
        }
      end
    end

    def self.service_role_policy_document
      with_encoded_document do
        {
          "Statement" =>  [
            {
              "Action" =>  [
                "ec2:*",
                "iam:PassRole",
                "cloudwatch:*",
                "elasticloadbalancing:*",
                "rds:*"
              ],
              "Effect" => "Allow",
              "Resource" => [
                "*"
              ] 
            }
          ]
        }
      end
    end

    def self.assume_role_policy_document
      with_encoded_document do
        {
          "Version" => "2008-10-17",
          "Statement" => [
            {
              "Sid" => "",
              "Effect" => "Allow",
              "Principal" => {
                "Service" => "opsworks.amazonaws.com"
              },
              "Action" => "sts:AssumeRole"
            }
          ]
        }
      end
    end
  end
end
