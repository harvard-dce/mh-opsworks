module Cluster
  class Config
    def initialize
      json_file = ENV.fetch('CLUSTER_CONFIG_FILE', 'cluster_config.json')
      @json_content = File.read(json_file)
    end

    def credentials
      Aws::Credentials.new(
        parsed[:credentials][:access_key_id],
        parsed[:credentials][:secret_access_key]
      )
    end

    def parsed
      JSON.parse(@json_content, symbolize_names: true)
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
        puts "\n#{ENV['CLUSTER_CONFIG_FILE']} configuration is invalid:\n\n"
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
