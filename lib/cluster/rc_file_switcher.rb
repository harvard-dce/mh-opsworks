module Cluster
  class RcFileSwitcher
    RC_FILE = '.mhopsworks.rc'

    def initialize(config_file: 'cluster_config_default.json.erb', secrets_file: 'secrets.json')
      @config_file = config_file
      @secrets_file = secrets_file
    end

    def write
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