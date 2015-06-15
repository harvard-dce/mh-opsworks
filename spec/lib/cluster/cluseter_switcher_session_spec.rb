describe Cluster::ClusterSwitcherSession do
  context '#choose_cluster' do
    it 'downloads and sets the cluster config when an existing one is chosen' do
      cluster_file = 'a cluster file'
      allow(Cluster::RemoteConfigs).to receive(:all).and_return([cluster_file])

      session = described_class.new
      allow(session).to receive(:set_cluster_to)
      allow(session).to receive(:download_latest_cluster_config_for)
      allow(STDIN).to receive(:gets).and_return('0')
      allow(Cluster::Assets).to receive(:get_support_asset)

      session.choose_cluster

      expect(session).to have_received(:download_latest_cluster_config_for).with(cluster_file)
      expect(session).to have_received(:set_cluster_to).with(cluster_file)
    end
  end
end
