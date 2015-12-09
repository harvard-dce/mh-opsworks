module Cluster
  module ConfigChecks
    class RDSUserInfoNotDefined < StandardError; end
    class RDSDatabaseInstanceNotDefined < StandardError; end
    class RDSDatabaseNameNotDefined < StandardError; end

    class Database < Base
      def self.sane?
        if ! rds_config[:master_user_password] || ! rds_config[:master_username]
          raise RDSUserInfoNotDefined.new('You need to define a master_user_password and master_username in the RDS configuration')
        end
        if ! rds_config[:allocated_storage] || ! rds_config[:db_instance_class]
          raise RDSDatabaseInstanceNotDefined.new('You need to define the allocated_storage and db_instance_class in the RDS configuration')
        end
        if ! rds_config[:db_name]
          raise RDSDatabaseNameNotDefined.new('You need to define the database name in the RDS configuration')
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Database)
