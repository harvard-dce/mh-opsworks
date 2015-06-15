module Cluster
  class ConfigCreationSession
    attr_accessor :variant, :name, :cidr_block_root, :git_url, :git_revision

    def choose_variant
      puts "Please choose the size of the cluster you'd like to deploy.\n\n"
      keys = []
      Cluster::ConfigCreator::VARIANTS.each do |key, variant|
        keys << key
        puts %Q|#{key}: #{variant[:description]}|
      end
      print %Q|\nOne of #{keys.join(', ')}: |
      variant_choice = STDIN.gets.chomp.to_sym
      return choose_variant unless keys.include?(variant_choice)

      @variant = variant_choice
    end

    def get_cluster_name
      print "\nA name for your stack: "
      name_choice = STDIN.gets.chomp

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

    def get_git_url
      print "\nThe URL to the git repository: "
      git_url = STDIN.gets.chomp

      unless git_url.match(/^git@|https:\/\//i)
        return get_git_url
      end

      @git_url = git_url
    end

    def get_git_revision
      print "\nThe branch, tag, or revision to deploy (hit enter to default to master): "
      git_revision = STDIN.gets.chomp

      if git_revision.match(/^\s?$/)
        @git_revision = 'master'
      else
        @git_revision = git_revision
      end
    end

    private

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
