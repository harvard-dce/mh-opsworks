module Cluster
  class RDS < Base
    include Waiters

    def self.all
      rds_instances = []
      rds_client.describe_db_instances.inject([]){ |memo, page| memo + page.db_instances }.each do |rds|
        rds_instances << construct_instance(rds)
      end
      rds_instances
    end

    def self.find_or_create
      rds = find_existing
      rds_instance = if rds
                       construct_instance(rds)
                     else
                       create_rds
                     end
      create_event_subscriptions

      rds_instance
    end

    def self.delete
      if find_existing
        rds_client.delete_db_instance(
          db_instance_identifier: rds_name,
          # This is because we're doing backups out-of-band and
          # they live in the shared NFS
          skip_final_snapshot: true
        )
        wait_until_rds_instance_deleted(rds_name)
      end
    end

    def self.find_existing
      all.find do |rds|
        rds.db_instance_identifier == rds_name
      end
    end

    def self.create_rds
      # Create optional read replicas
      # Create backup policies
      # Set AZ to be the primary?
      vpc = VPC.find_existing
      sg_finder = SecurityGroupFinder.new(vpc)
      sg_group_id = sg_finder.security_group_id_for('AWS-OpsWorks-Custom-Server')
      db_subnet_group_name = find_db_subnet_group.db_subnet_group_name
      base_parameters = rds_config

      parameters = {
        db_instance_identifier: rds_name,
        db_subnet_group_name: db_subnet_group_name,
        tags: [ {
          key: "opsworks:stack",
          value: stack_config[:name],
        } ],
        vpc_security_group_ids: [ sg_group_id ],

        auto_minor_version_upgrade: false,
        copy_tags_to_snapshot: true,
        engine: 'MySQL',
        engine_version: '5.6.23',
        multi_az: false,
        preferred_backup_window: "05:02-05:32",
        preferred_maintenance_window: "thu:09:31-thu:10:01",
        publicly_accessible: false,
        storage_type: 'gp2',
      }.merge(base_parameters)

      response = rds_client.create_db_instance(parameters)
      wait_until_rds_instance_available(rds_name)

      construct_instance(response.db_instance)
    end

    private

    def self.create_event_subscriptions
      EventSubscriptionCreator.create
    end

    def self.find_db_subnet_group
      rds_client.describe_db_subnet_groups.inject([]){ |memo, page| memo + page.db_subnet_groups }.find do |db_subnet_group|
        db_subnet_group.db_subnet_group_name.match(/^#{vpc_name}-dbsubnetgroup/)
      end
    end

    def self.construct_instance(rds)
      Aws::RDS::DBInstance.new(rds.db_instance_identifier, client: rds_client)
    end
  end
end
