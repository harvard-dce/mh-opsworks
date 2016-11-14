module Cluster
  class ConfigCreationSession
    attr_accessor :variant, :name, :cidr_block_root, :git_url, :git_revision,
      :export_root, :nfs_server_host, :primary_az, :secondary_az, :project_tag,
      :include_analytics

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

    def get_project_tag
      print "\nWhat value for Project Tag? [MH]: "
      project_tag = STDIN.gets.strip.chomp

      # the default is set in the template mainly because, in tests, this isn't
      # run and project_tag doesnt' get a default value
      @project_tag = project_tag
    end

    def zadara_variant?
      variant.match(/zadara/)
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
        puts "Cluster names should be only letters, numbers, spaces and hyphens."
        return get_cluster_name
      end

      @name = name_choice
    end

    def compute_cidr_block_root
      @cidr_block_root = find_unused_cidr_block_root
    end

    def compute_azs
      picker = Cluster::AZPicker.new
      @primary_az = picker.primary_az
      @secondary_az = picker.secondary_az
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
      default = ENV.fetch('MATTERHORN_GIT_URL', '')
      print "\nThe git URL to the matterhorn repo, e.g. git@bitbucket.org [#{default}]: "
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
      print "\nThe branch, tag, or revision to deploy [master]: "
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
