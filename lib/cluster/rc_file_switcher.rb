module Cluster
  class RcFileSwitcher
    RC_FILE = '.ocopsworks.rc'

    def initialize(config_file: 'minimal_cluster_config.json', secrets_file: 'secrets.json')
      @config_file = config_file
      @secrets_file = secrets_file
    end

    def write
      # Ensure we allow the correct file to load when we've switched configs
      ENV.delete('CLUSTER_CONFIG_FILE')

      File.open(RC_FILE, 'w') do |f|
        f.write "cluster=#{@config_file}\n"
        f.write "secrets=#{@secrets_file}\n"
      end
    end

    def delete
      if File.exists?(RC_FILE)
        File.unlink(RC_FILE)
      end
    end
  end
end
