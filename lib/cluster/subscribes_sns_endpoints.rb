module Cluster
  class SubscribesSnsEndpoints < Base
    def self.subscribe
      topic_arn = get_topic_arn
      sns_endpoints = stack_custom_json.fetch(:sns_endpoints, {})
      sns_endpoints.each { |e|
        protocol, endpoint = e.flatten
        if ! endpoint.empty?
          puts "Subscribing #{protocol} #{endpoint} to #{topic_name}; check your inbox for the confiration message."
          sns_client.subscribe(
            topic_arn: topic_arn,
            protocol: protocol,
            endpoint: endpoint
          )
        end
      }
    end
  end
end
