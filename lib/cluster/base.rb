module Cluster
  class Base
    require 'uri'
    require 'json'

    def self.with_encoded_document
      JSON.dump(
        yield
      )
    end

    def self.json_encode(string)
      JSON.dump(string)
    end

    # Allows the construction of client interfaces at the instance level
    def construct_instance(instance_id)
      self.class.construct_instance(instance_id)
    end

    def self.instance_profile_name
      %Q|#{service_role_name}-instance-profile|
    end

    def self.root_config
      config.parsed
    end

    def self.instances_config_in_layer(layer_name)
      stack_config[:layers].find do |layer|
        layer[:name] == layer_name
      end.fetch(:instances, {})
    end

    def self.app_config
      stack_config[:app]
    end

    def self.stack_config
      config.parsed[:stack]
    end

    def self.stack_chef_config
      stack_config.fetch(:chef, {})
    end

    def self.service_role_config
      config.parsed[:stack][:service_role]
    end

    def self.service_role_name
      service_role_config[:name]
    end

    def self.instance_profile_policy_document
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
                "cloudwatch:GetMetricStatistics",
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

    def self.config
      @@config ||= Config.new
    end

    def self.iam_client
      Aws::IAM::Client.new(
        region: config.parsed[:region],
        credentials: config.credentials
      )
    end

    def self.ec2_client
      Aws::EC2::Client.new(
        region: config.parsed[:region],
        credentials: config.credentials
      )
    end

    def self.opsworks_client
      Aws::OpsWorks::Client.new(
        region: config.parsed[:region],
        credentials: config.credentials
      )
    end
  end
end
