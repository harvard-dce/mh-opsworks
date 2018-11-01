module Cluster
  class RegistersRDSInstance < Base
    def self.register

      writer_arn = Cluster::RDS.writer_instance_arn
      return if already_registered?(writer_arn)

      opsworks_client.register_rds_db_instance(
        stack_id: Stack.find_existing.id,
        rds_db_instance_arn: writer_arn,
        db_user: rds_config[:master_username],
        db_password: rds_config[:master_user_password]
      )
    end

    private

    def self.already_registered?(writer_arn)
      opsworks_client.describe_rds_db_instances(stack_id: Stack.find_existing.id).rds_db_instances.find do |rds_db_instance|
        rds_db_instance.rds_db_instance_arn == writer_arn
      end
    end
  end
end
