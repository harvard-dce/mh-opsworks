module Cluster
  module ConfigChecks
    class RDSUserInfoNotDefined < StandardError; end
    class RDSDatabaseUnsupportedInstanceClass < StandardError; end
    class RDSDatabaseNameNotDefined < StandardError; end

    class Database < Base
      def self.sane?
        if ! rds_config[:master_user_password] || ! rds_config[:master_username]
          raise RDSUserInfoNotDefined.new('You need to define a master_user_password and master_username in the RDS configuration')
        end
        if ! rds_config[:db_instance_class] ||
            (! rds_config[:db_instance_class].match(/^db\.r/) &&
            ! ["db.t2.medium", "db.t2.small"].include?(rds_config[:db_instance_class]))
          raise RDSDatabaseUnsupportedInstanceClass.new('Invalid db instance class. Supported types include all r3|r4 classes, plus db.t2.small and db.t2.medium.')
        end
        if ! rds_config[:db_name]
          raise RDSDatabaseNameNotDefined.new('You need to define the database name in the RDS configuration')
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::Database)
