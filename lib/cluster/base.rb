module Cluster
  class Base
    def self.config
      @@config ||= Config.new
    end

    def self.ec2_client
      @@ec2 ||= Aws::EC2::Client.new(
        region: config.json[:region],
        credentials: config.credentials
      )
    end

    def self.opsworks_client
      @@opsworks ||= Aws::OpsWorks::Client.new(
        region: config.json[:region],
        credentials: config.credentials
      )
    end
  end
end
