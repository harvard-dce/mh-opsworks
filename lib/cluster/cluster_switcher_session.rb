module Cluster
  class ClusterSwitcherSession
    attr_reader :configs

    def initialize
      @configs = Cluster::RemoteConfigs.all
    end

    def choose_cluster
      puts
      puts "Please choose a cluster by number: (ctrl-c to quit)\n\n"
      configs.each_with_index do |config, index|
        config_name = config.gsub('cluster_config-', '')
        config_name.gsub!('.json', '')
        print %Q|#{index}. |
        if Cluster::Base.stack_shortname == config_name
          print '* '
        end
        puts config_name
      end

      puts
      puts "* = active cluster"

      print "\nCluster number: "
      cluster_number_input = STDIN.gets.strip.chomp
      cluster_number = cluster_number_input.to_i
      cluster_name = configs[cluster_number]
      if cluster_number_input.match(/^\d+$/) && cluster_name
        set_cluster_to(cluster_name)
        download_latest_cluster_config_for(cluster_name)
        return
      end
      puts "Please choose a valid cluster.\n"
      choose_cluster
    end

    def download_latest_cluster_config_for(cluster_name)
      cluster_contents = Cluster::Assets.get_support_asset(
        file_name: cluster_name,
        bucket: Cluster::Base.cluster_config_bucket_name
      )
      File.open(cluster_name, 'w') do |f|
        f.write cluster_contents
      end
    end

    def set_cluster_to(cluster_name)
      puts "Switching to #{cluster_name}"
      Cluster::RcFileSwitcher.new(config_file: cluster_name).write
    end
  end
end
