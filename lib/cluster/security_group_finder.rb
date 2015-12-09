module Cluster
  class SecurityGroupFinder < Base
    attr_reader :vpc, :name

    def initialize(vpc)
      @vpc = vpc
    end

    def find(name)
      self.class.ec2_client.describe_security_groups.inject([]){ |memo, page| memo + page.security_groups }.find do |group|
        # This is tightly coupled to the implementation in templates/OpsWorksinVPC.template
        group.group_name.match(/#{name}/) && group.vpc_id == vpc.vpc_id
      end
    end

    def security_group_id_for(name)
      sg = find(name)
      sg && sg.group_id
    end
  end
end
