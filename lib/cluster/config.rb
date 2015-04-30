module Cluster
  class Config
    def initialize
      json_file = ENV.fetch('CLUSTER_CONFIG_FILE', 'cluster_config.json')
      secrets_file = ENV.fetch('SECRETS_FILE', 'secrets.json')
      @secrets_content = File.read(secrets_file)
      @json_content = File.read(json_file)
    end

    def credentials
      Aws::Credentials.new(
        parsed_secrets[:access_key_id],
        parsed_secrets[:secret_access_key]
      )
    end

    def parsed
      JSON.parse(@json_content, symbolize_names: true)
    end

    def parsed_secrets
      JSON.parse(@secrets_content, symbolize_names: true)
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
  end
end
