module Cluster
  class Config
    attr_reader :config_content, :secrets_content

    def initialize
      json_file = negotiate_config_file
      secrets_file = negotiate_secrets_file
      @config_content = File.read(json_file)
      @secrets_content = File.read(secrets_file)
    end

    def version
      parsed[:version].to_i
    end

    def active_config
      negotiate_config_file
    end

    def active_secrets
      negotiate_secrets_file
    end

    def credentials
      Aws::Credentials.new(
        parsed_secrets[:access_key_id],
        parsed_secrets[:secret_access_key]
      )
    end

    def parsed
      JSON.parse(config_content, symbolize_names: true)
    end

    def parsed_secrets
      JSON.parse(secrets_content, symbolize_names: true)
    end

    def sane?
      errors = []
      begin
        self.class.check_registry.each do |klass|
          klass.sane?
        end
      rescue => e
        errors << e
      end

      if errors.any?
        puts "\nConfiguration is invalid:\n\n"
        puts errors.join("\n")
        exit 1
      else
        true
      end
    end

    def self.append_to_check_registry(klass)
      check_registry << klass
    end

    def self.check_registry
      @@check_registry ||= []
    end

    private

    def from_rc_file
      rc_file_name = '.mhopsworks.rc'
      return {} unless File.exists?(rc_file_name)

      parse_rc_file(rc_file_name)
    end

    def parse_rc_file(file_name)
      config = {}
      File.read(file_name).split(/\n/).each do |line|
        next if line.match(/^\s?#/)
        parsed_line = line.split(/=/)
        config[parsed_line[0]] = parsed_line[1]
      end
      config
    end

    def negotiate_secrets_file
      config_for('secrets','secrets.json','SECRETS_FILE')
    end

    def negotiate_config_file
      config_for('cluster','templates/minimal_cluster_config.json', 'CLUSTER_CONFIG_FILE')
    end

    def config_for(config_type, default_file, env_var)
      config_from_rc_file = from_rc_file[config_type]
      if ENV[env_var] && File.exists?(ENV[env_var])
        return ENV[env_var]
      end
      if config_from_rc_file && File.exists?(config_from_rc_file)
        return config_from_rc_file
      end
      default_file
    end
  end
end
