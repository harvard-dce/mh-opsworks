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
      begin
        parsed
      rescue => e
        raise JSONFormatError.new(e)
      end
    end
  end
end
