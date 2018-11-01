describe Cluster::ConfigChecks::Database do
  include EnvironmentHelpers
  context 'RDS databases' do
    it 'checks for user info' do
      stub_config_to_include({
        rds: { foo: '', db_instance_class: 'db.r4.foo', db_name: 'foodatabase' }
      })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSUserInfoNotDefined
      )
    end

    it 'checks for database instance class defined' do
      stub_config_to_include({
        rds: { master_user_password: '123123', master_username: 'rootfoobar', db_name: 'foodatabase' }
                             })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSDatabaseUnsupportedInstanceClass
      )
    end

    it 'checks for database instance class valid' do
      stub_config_to_include({
        rds: { master_user_password: '123123', master_username: 'rootfoobar', db_name: 'foodatabase', db_instance_class: 'db.m5.large'}
      })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSDatabaseUnsupportedInstanceClass
      )
    end

    it 'checks for database name' do
      stub_config_to_include({
        rds: {
          master_user_password: '123123', master_username: 'rootfoobar',
          db_instance_class: 'db.r3.foo'
        }
      })
      expect { described_class.sane? }.to raise_error(
        Cluster::ConfigChecks::RDSDatabaseNameNotDefined
      )
    end
  end
end
