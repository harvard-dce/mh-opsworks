describe Cluster::RDS do
  include EnvironmentHelpers
  include ClientStubHelpers

  context '.all' do
    it 'uses the rds client' do
      stub_rds_client do |rds|
        rds.stub_responses(
          :describe_db_clusters,
          db_clusters: [ { db_cluster_identifier: 'a-db-cluster-id'} ]
        )
      end
      all = described_class.all

      expect(all.map{|cluster| cluster.db_cluster_identifier}).to include 'a-db-cluster-id'
    end
  end

  context '.find_or_create' do
    it 'finds an existing cluster based on identifier' do
      stub_rds_client do |rds|
        rds.stub_responses(
          :describe_db_clusters,
          db_clusters: [ existing_db_cluster ]
        )
      end
      stub_config_to_include(stack: {
          name: 'test',
          chef: {}
      })
      stub_config_to_include(
          rds: {
              master_username: 'foo',
              master_user_passwod: 'bar',
              db_instance_class: 'db.r4.large',
              db_name: 'baz'
          }
      )
      cluster = described_class.find_or_create

      expect(cluster.db_cluster_identifier).to eq existing_db_cluster[:db_cluster_identifier]
    end
  end

  context '.stop' do
    it 'won\'t stop the db in a production opsworks cluster' do
      stub_config_to_include(stack: {
          name: 'my-sweet-production-opencast'
      })
      stub_rds_client do |rds|
        rds.stub_responses(
               :describe_db_clusters,
               db_clusters: [ existing_db_cluster ]
        )
      end

      expect { Cluster::RDS.stop }.to output(/^Refusing/).to_stdout
    end
  end
end

def existing_db_cluster
  {
      db_cluster_identifier: existing_db_cluster_name
  }
end

def existing_db_cluster_name
  'test-cluster'
end


