module Cluster
  class RDS < Base
    include Waiters

    def self.all
      clusters = []
      rds_client.describe_db_clusters.inject([]){ |memo, page| memo + page.db_clusters }.each do |cluster|
        clusters << construct_cluster(cluster)
      end
      clusters
    end

    def self.delete
      stack = cloudformation_client.describe_stacks.inject([]){ |memo, page| memo + page.stacks }.find do |stack|
        stack.stack_name == rds_cfn_stack_name
      end

      if stack
        cluster = find_existing
        if cluster
          rds_client.modify_db_cluster({
            db_cluster_identifier: cluster.db_cluster_identifier,
            apply_immediately: true,
            deletion_protection: false
          })
          wait_until_rds_cluster_available(cluster)
        end

        cloudformation_client.delete_stack(
            stack_name: stack.stack_id
        )
        wait_until_stack_delete_completed(stack.stack_id)
      end
    end

    def self.update(update_now=false)
      parameters = get_parameters
      parameters.delete(:timeout_in_minutes)

      begin
        if update_now
          stack = cloudformation_client.update_stack(parameters)
          wait_until_stack_update_completed(stack.stack_id)
        else
          parameters[:change_set_name] = "rds-update-#{Time.now.to_i}"
          resp = cloudformation_client.create_change_set(parameters)
          change_set = cloudformation_client.describe_change_set({
             change_set_name: resp.id
          })
          if change_set.status == 'FAILED' && change_set.status_reason =~/didn't contain changes/
            cloudformation_client.delete_change_set({
              change_set_name: resp.id
            })
            raise "No updates"
          end
          puts "Change set #{change_set.change_set_name} created. Review and approve via Cloudformation web console."
        end
      rescue => e
        puts e.message
        unless e.message.start_with? "No updates"
          raise
        end
      end

      find_existing
    end

    def self.find_or_create
      cluster = find_existing

      if cluster
        return construct_cluster(cluster)
      end

      parameters = get_parameters
      stack = cloudformation_client.create_stack(parameters)
      wait_until_stack_build_completed(stack.stack_id)
      find_existing
    end

    def self.find_existing
      all.find do |cluster|
        cluster.db_cluster_identifier == rds_name
      end
    end

    def self.writer_instance_arn
      cluster = find_existing
      writer = cluster.db_cluster_members.find do |member|
        member.is_cluster_writer
      end
      rds_db_instance_arn(writer.db_instance_identifier)
    end

    def self.start
      cluster = find_existing
      if !cluster
        puts "No db cluster found!"
      elsif cluster.status == "available"
        puts "DB cluster is already online"
      else
        rds_client.start_db_cluster({ db_cluster_identifier: cluster.db_cluster_identifier })
        wait_until_rds_cluster_available(cluster)
      end
    end

    def self.stop

      if prod_cluster?
        puts "Refusing to stop production cluster db"
        return
      end

      cluster = find_existing
      if cluster && cluster.status == "available"
        rds_client.stop_db_cluster({ db_cluster_identifier: cluster.db_cluster_identifier })
        wait_until_rds_cluster_stopped(cluster)
      end
    end

    private

    def self.construct_cluster(rds)
      Aws::RDS::DBCluster.new(rds.db_cluster_identifier, client: rds_client)
    end

    def self.construct_instance(rds)
      Aws::RDS::DBInstance.new(rds.db_instance_identifier, client: rds_client)
    end

    def self.get_parameters
      base_parameters = rds_config
      parameters = [
          {
              parameter_key: 'DBClusterIdentifier',
              parameter_value: rds_name
          },
          {
              parameter_key: 'DBInstancePrefix',
              parameter_value: rds_instance_prefix
          },
          {
              parameter_key: 'ParentVpcStack',
              parameter_value: vpc_name
          },
          {
              parameter_key: 'DBMasterUser',
              parameter_value: base_parameters[:master_username]
          },
          {
              parameter_key: 'DBMasterUserPassword',
              parameter_value: base_parameters[:master_user_password]
          },
          {
              parameter_key: 'PreferredBackupWindow',
              parameter_value: "05:02-05:32"
          },
          {
              parameter_key: 'PreferredMaintenanceWindow',
              parameter_value: "thu:09:31-thu:10:01"
          },
          {
              parameter_key: "DBInstanceClass",
              parameter_value: base_parameters[:db_instance_class]
          },
          {
              parameter_key: "DBName",
              parameter_value: base_parameters[:db_name]
          },
          {
              parameter_key: "EnablePerformanceInsights",
              parameter_value: rds_supports_performance_insights?.to_s
          },
          {
              parameter_key: "MultiAZ",
              parameter_value: base_parameters[:multi_az].to_s
          },
          {
              parameter_key: "BackupRetentionPeriod",
              parameter_value: base_parameters[:backup_retention_period].to_s
          },
          {
              parameter_key: "SnsTopicArn",
              parameter_value: get_topic_arn
          }
      ]

      {
          stack_name: rds_cfn_stack_name,
          template_body: File.read('./templates/RDSCluster.template.yml'),
          parameters: parameters,
          timeout_in_minutes: 30,
          tags: [
              {
                  key: 'opsworks:stack',
                  value: stack_config[:name]
              }
          ].concat(stack_custom_tags)
      }
    end

  end
end
