module Cluster
  class Base
    require 'uri'
    require 'json'
    require 'concurrent-ruby'
    require 'net/http'
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

    def self.get_topic_arn
      # create_topic is idempotent
      sns_client.create_topic(name: topic_name).topic_arn
    end

    def self.storage_config
      stack_custom_json.fetch(:storage, {})
    end

    def self.external_storage?
      storage_config[:type] == 'external'
    end

    def self.show_zadara_tasks?
      stack_name = config.parsed[:stack][:name]
      external_storage? && ! stack_name.match(/prod|prd/i)
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
                "logs:*",
                "lambda:InvokeFunction",
                "sns:CreateTopic",
                "opsworks:DescribeInstances",
                "opsworks:DescribeLayers",
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
                "logs:*",
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
            },
            {
                "Sid" => "",
                "Effect" => "Allow",
                "Principal" => {
                    "Service" => "vpc-flow-logs.amazonaws.com"
                },
                "Action" => "sts:AssumeRole"
            }
          ]
        }
      end
    end
  end
end
