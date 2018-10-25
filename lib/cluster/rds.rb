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
        parameters = {
          db_instance_identifier: rds_name,
          skip_final_snapshot: true
        }
        rds_client.delete_db_instance(parameters)
        wait_until_rds_instance_deleted(rds_name)
      end
      if hibernate_snapshot_exists
        puts "Deleting RDS hibernate snapshot"
        rds_client.delete_db_snapshot({ db_snapshot_identifier: db_hibernate_snapshot_id })
      end
    end

    def self.delete_with_snapshot(final_snapshot)
      if find_existing
        parameters = {
          db_instance_identifier: rds_name,
          final_db_snapshot_identifier: final_snapshot
        }
        rds_client.delete_db_instance(parameters)
        wait_until_rds_instance_deleted(rds_name)
      end
    end

    def self.find_existing
      all.find do |rds|
        rds.db_instance_identifier == rds_name
      end
    end

    def self.hibernate
      if stack_shortname.match(/prod|prd/i)
        puts "Refusing to hibernate prod db"
        return
      end

      if find_existing
        puts "Hibernating RDS instance via snapshot + delete"
        # turn off auto backups. without this the restore wastes time doing an immediate backup.
        # we'll turn it back on at the end of the restore operation
        rds_client.modify_db_instance({
          backup_retention_period: 0,
          apply_immediately: true,
          db_instance_identifier: rds_name
        })
        # wait until our modification is complete and the instance is available again
        wait_for_rds_instance_modification(rds_name)

        delete_with_snapshot(db_hibernate_snapshot_id)
      else
        puts "No RDS instance to hibernate"
      end
    end

    def self.restore
      if find_existing
        puts "RDS instance already online"
        return
      end

      unless hibernate_snapshot_exists
        puts "Unable to find hibernate snapshot: #{ db_hibernate_snapshot_id }... creating a fresh instance"
        return create_rds
      end

      puts "Restoring RDS instance"

      parameters = get_create_params
      parameters[:db_snapshot_identifier] = db_hibernate_snapshot_id

      # restore doesn't take these params
      [ :db_name, :preferred_backup_window, :preferred_maintenance_window, :backup_retention_period,
        :vpc_security_group_ids, :engine_version, :allocated_storage, :master_username, :master_user_password,
        :db_parameter_group_name
      ].each do |s|
        parameters.delete(s)
      end

      response = rds_client.restore_db_instance_from_db_snapshot(parameters)
      wait_until_rds_instance_available(rds_name)

      # restore also doesn't let you set security groups on initial creation, so we have to do that in a follow-up call
      # also, we can now re-enable the backup setting
      modify_params = {
          db_instance_identifier: rds_name,
          backup_retention_period: rds_config[:backup_retention_period],
          vpc_security_group_ids: sg_group_ids,
          # if unset instance will get the default mysql5.6 param group
          db_parameter_group_name: rds_config[:db_parameter_group_name]
      }
      rds_client.modify_db_instance(modify_params)

      puts "RDS instance restored. Rebooting to apply parameter group and other modifications."
      rds_client.reboot_db_instance({ db_instance_identifier: rds_name, force_failover: false })
      wait_until_rds_instance_available(rds_name)

      rds_client.delete_db_snapshot({ db_snapshot_identifier: db_hibernate_snapshot_id })
      construct_instance(response.db_instance)
    end

    def self.create_rds
      parameters = get_create_params

      # don't set this on initial create as it causes rds to do an immediate backup (which slows us down)
      backup_retention_period = parameters.delete(:backup_retention_period)

      response = rds_client.create_db_instance(parameters)
      wait_until_rds_instance_available(rds_name)

      # set the backup retention period now as now that the instance exists the immediate backup
      # can happen concurrent with other, subsequent cluster init stuff
      rds_client.modify_db_instance({
          db_instance_identifier: rds_name,
          backup_retention_period: backup_retention_period
      })
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

    def self.sg_group_ids
      vpc = VPC.find_existing
      sg_finder = SecurityGroupFinder.new(vpc)
      [
        sg_finder.security_group_id_for('OpsworksLayerSecurityGroupCommon')
      ]
    end

    def self.construct_instance(rds)
      Aws::RDS::DBInstance.new(rds.db_instance_identifier, client: rds_client)
    end

    def self.create_custom_tags
      if stack_custom_tags.empty?
        return
      end

      rds_client.add_tags_to_resource({
        resource_name: rds_db_instance_arn,
        tags: stack_custom_tags
      })
    end

    def self.get_create_params
      db_subnet_group_name = find_db_subnet_group.db_subnet_group_name
      base_parameters = rds_config

      {
          db_instance_identifier: rds_name,
          db_subnet_group_name: db_subnet_group_name,
          vpc_security_group_ids: sg_group_ids,
          tags: [{
            key: "opsworks:stack",
            value: stack_config[:name],
          }].concat(stack_custom_tags),
          auto_minor_version_upgrade: false,
          copy_tags_to_snapshot: true,
          engine: 'MySQL',
          multi_az: false,
          engine_version: '5.6.34',
          storage_type: 'gp2',
          preferred_backup_window: "05:02-05:32",
          preferred_maintenance_window: "thu:09:31-thu:10:01",
      }.merge(base_parameters)
    end

    def self.hibernate_snapshot_exists
      rds_client.describe_db_snapshots({
          db_instance_identifier: rds_name,
          db_snapshot_identifier: db_hibernate_snapshot_id
      }).db_snapshots.any?
    end
  end
end
