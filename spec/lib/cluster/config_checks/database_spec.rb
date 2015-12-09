describe Cluster::ConfigChecks::Database do
  include EnvironmentHelpers
  context 'RDS databases' do
    it 'checks for user info' do
      stub_config_to_include({
        rds: { foo: '', db_instance_class: 'a_class', allocated_storage: 100, db_name: 'foodatabase' }
      })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSUserInfoNotDefined
      )
    end

    it 'checks for database instance metadata' do
      stub_config_to_include({
        rds: { master_user_password: '123123', master_username: 'rootfoobar', db_name: 'foodatabase' }
      })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSDatabaseInstanceNotDefined
      )
    end

    it 'checks for database name' do
      stub_config_to_include({
        rds: {
          master_user_password: '123123', master_username: 'rootfoobar',
          allocated_storage: 100, db_instance_class: 'fooinstance'
        }
      })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSDatabaseNameNotDefined
      )
    end
  end
end
