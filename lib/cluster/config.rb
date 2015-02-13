module Cluster
  class Config
    def initialize
      json_file = ENV.fetch('CLUSTER_CONFIG_FILE', 'cluster_config.json')
      @json_content = File.read(json_file)
    end

    def credentials
      Aws::Credentials.new(
        json[:credentials][:access_key_id],
        json[:credentials][:secret_access_key]
      )
    end

    def json
      JSON.parse(@json_content, symbolize_names: true)
    end

    def sane?
      begin
        json
      rescue => e
        raise JSONFormatError.new(e)
      end
    end
  end
end
