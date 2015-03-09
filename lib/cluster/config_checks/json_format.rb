module Cluster
  module ConfigChecks
    class JSONFormatError < StandardError; end

    class JsonFormat < Cluster::Base
      def self.sane?
        begin
          config = Cluster::Config.new
          config.parsed
          config.parsed_credentials
        rescue => e
          raise JSONFormatError.new(e)
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::JsonFormat)
