module Cluster
  class SecurityGroupFinder < Base
    attr_reader :vpc, :name

    def initialize(vpc)
      @vpc = vpc
    end

    def find(name)
      vpc_filter = { filters: [{ name: "vpc-id", values: [vpc.vpc_id] }] }
      self.class.ec2_client.describe_security_groups(vpc_filter).inject([]){ |memo, page| memo + page.security_groups }.find do |group|
        # This is tightly coupled to the implementation in templates/OpsWorksinVPC.template
        group.group_name.match(/#{name}/)
      end
    end

    def security_group_id_for(name)
      sg = find(name)
      sg && sg.group_id
    end
  end
end
