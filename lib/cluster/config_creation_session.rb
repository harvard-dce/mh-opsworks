module Cluster
  class ConfigCreationSession
    attr_accessor :variant, :name, :cidr_block_root, :git_url, :git_revision,
      :export_root, :nfs_server_host, :subnet_azs,
      :include_analytics, :cookbook_revision, :include_utility, :sns_email

    def choose_variant
      puts "\nPlease choose the size of the cluster you'd like to deploy.\n\n"
      default = Cluster::ConfigCreator::DEFAULT_VARIANT
      keys = []
      Cluster::ConfigCreator::VARIANTS.each do |key, variant|
        keys << key
        puts %Q|- #{key}: #{variant[:description]}|
      end
      print %Q|\nOne of #{keys.join(', ')} [#{default}]: |
      variant_choice = STDIN.gets.strip.chomp.to_sym
      if variant_choice.match(/^\s?$/)
        variant_choice = default
      end
      return choose_variant unless keys.include?(variant_choice)

      @variant = variant_choice
    end

    def zadara_variant?
      variant.match(/zadara/)
    end

    def ami_builder?
      variant.to_s == "ami_builder"
    end

    def get_export_root
      print "\nThe path to the volume you're exporting from zadara: "
      export_root = STDIN.gets.strip.chomp

      if ! export_root.match(/^\/[a-z\d\-\/]+/)
        puts "Please enter an absolute unix path, something like:"
        puts "/export/data"
        return get_export_root
      end

      @export_root = export_root
    end

    def get_nfs_server_host
      print "\nThe IP address of the zadara NFS server: "
      nfs_server_host = STDIN.gets.strip.chomp

      if ! nfs_server_host.match(/^\d+[\.\d]+/)
        puts 'Please enter something that looks like an IP address.'
        return get_nfs_server_host
      end

      @nfs_server_host = nfs_server_host
    end

    def get_cluster_name
      print "\nA name for your stack: "
      name_choice = STDIN.gets.strip.chomp

      @all_stack_names = Cluster::Stack.all.map { |stack| stack.name.downcase }
      if @all_stack_names.include?(name_choice.downcase)
        puts "That name is in use. Please choose another"
        return get_cluster_name
      end

      if ! cluster_name_ok?(name_choice)
        puts "Cluster names should be only lowercase letters, numbers, spaces and hyphens."
        return get_cluster_name
      end

      @name = name_choice.downcase
    end

    def compute_cidr_block_root
      @cidr_block_root = find_unused_cidr_block_root
    end

    def compute_azs
      picker = Cluster::AZPicker.new
      @subnet_azs = picker.subnet_azs
    end

    def compute_default_users
      local_user_account = ENV['USER']
      iam_user_account = Cluster::Base.iam_client.get_user.user.user_name
      optimal_keyfile = find_optimal_keyfile
      ssh_public_key =
        if optimal_keyfile
          File.read(optimal_keyfile)
        end

      users = [
        {
          user_name: local_user_account,
          level: 'manage',
          allow_ssh: true,
          allow_sudo: true,
          ssh_public_key: ssh_public_key
        }
      ]
      if local_user_account != iam_user_account
        users << {
          user_name: iam_user_account,
          level: 'manage'
        }
      end

      users
    end

    def get_git_url
      default = ENV.fetch('OPENCAST_GIT_URL', '')
      print "\nThe git URL to the opencast repo, e.g. git@bitbucket.org:hudcede/matterhorn-dce-fork.git [#{default}]: "
      git_url = STDIN.gets.strip.chomp

      if git_url.match(/^\s?$/)
        git_url = default
      end

      unless git_url.match(/^git@|https:\/\//i)
        return get_git_url
      end

      @git_url = git_url
    end

    def get_git_revision
      print "\nThe Opencast branch, tag, or revision to deploy [master]: "
      git_revision = STDIN.gets.strip.chomp

      if git_revision.match(/^\s?$/)
        @git_revision = 'master'
      else
        @git_revision = git_revision
      end
    end

    def local_vs_opsworks
      print "\nCould the purpose of this cluster be accomplished using a local vagrant instance? [y/N]: "
      local_vs_opsworks = STDIN.gets.strip.chomp

      if local_vs_opsworks.downcase == 'y'
        print "Great! You just saved some money!\n"
        exit 0
      end
    end

    def analytics_node
      print "\nWould you like an analytics node? [y/N]: "
      include_analytics = STDIN.gets.strip.chomp

      if include_analytics.downcase == 'y'
        @include_analytics = true
      end
    end

    def get_cookbook_revision
      print "\nEnter the custom Chef cookbook revision, e.g. 'oc-master': "
      cookbook_revision = STDIN.gets.strip.chomp
      unless cookbook_revision == ''
        @cookbook_revision = cookbook_revision
      else
        puts "You must enter a custom cookbook revision or tag"
        get_cookbook_revision
      end
    end

    def utility_node
      print "\nWould you like a utility node? [y/N]: "
      include_utility = STDIN.gets.strip.chomp

      if include_utility.downcase == 'y'
        @include_utility = true
      end
    end

    def sns_email_subscription
      print "\nEnter an email address for cluster notifications [Enter for none]: "
      sns_email = STDIN.gets.strip.chomp
      if ! sns_email.empty?
        @sns_email = sns_email
      end
    end

    private

    def find_optimal_keyfile
      home = ENV['HOME']
      [%Q|#{home}/.ssh/id_rsa.pub|, %Q|#{home}/.ssh/id_dsa.pub|].find do |file|
        File.exists?(file)
      end
    end

    def find_unused_cidr_block_root
      active_blocks = Cluster::VPC.all.map { |vpc| vpc.cidr_block }
      open_block = (0..254).to_a.find do |root|
        ! active_blocks.include?(%Q|10.1.#{root}.0/24|)
      end
      %Q|10.1.#{open_block}|
    end

    def cluster_name_ok?(name)
      name.match(/^[a-zA-Z\d]+[a-zA-Z\d -]+$/)
    end

  end
end
