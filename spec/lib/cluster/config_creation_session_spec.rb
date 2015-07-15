describe Cluster::ConfigCreationSession do
  context '#choose_variant' do
    it 'accepts valid variants' do
      Cluster::ConfigCreator::VARIANTS.keys.each do |variant|
        session = described_class.new
        allow(STDIN).to receive(:gets).and_return(variant.to_s)

        session.choose_variant

        expect(session.variant).to eq variant
      end
    end
  end

  context '#get_cluster_name' do
    it 'sets the name to the chosen one with the name is not in use' do
      stack_result_double = double('stack result')
      allow(stack_result_double).to receive(:name).and_return('bleep')
      session = described_class.new

      allow(STDIN).to receive(:gets).and_return('foobar')
      allow(Cluster::Stack).to receive(:all).and_return([stack_result_double])

      session.get_cluster_name

      expect(session.name).to eq 'foobar'
    end
  end

  context '#get_git_url' do
    it 'accepts those beginning with "git@" or "https://"' do

      ['git@github.com:foo', 'https://github'].each do |git_url|
        session = described_class.new
        allow(STDIN).to receive(:gets).and_return(git_url)

        session.get_git_url

        expect(session.git_url).to eq git_url
      end
    end
  end

  context '#compute_default_users' do
    it 'includes the correct user accounts' do
      local_user_name = ENV['USER']
      remote_user_name = 'iam-user'
      allow(Cluster::Base).to receive_message_chain(:iam_client, :get_user, :user, user_name: remote_user_name)

      session = described_class.new

      default_users = session.compute_default_users.map{ |u| u[:user_name]}
      expect(default_users).to include(local_user_name, remote_user_name)
    end

    it 'does not include duplicate usernames' do
      local_user_name = ENV['USER']
      remote_user_name = local_user_name
      allow(Cluster::Base).to receive_message_chain(:iam_client, :get_user, :user, user_name: remote_user_name)

      session = described_class.new

      default_users = session.compute_default_users.map{ |u| u[:user_name]}
      expect(default_users).to include(local_user_name)
      expect(default_users.length).to eq 1
    end
  end
end
