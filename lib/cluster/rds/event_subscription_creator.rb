module Cluster
  class RDS::EventSubscriptionCreator < Base
    def self.create
      db_instance_identifier = rds_name
      if subscription_exists?
        subscription_attributes = get_subscription_attributes
        subscription_attributes.delete(:source_ids)
        rds_client.modify_event_subscription(subscription_attributes)
      else
        rds_client.create_event_subscription(get_subscription_attributes)
      end
    end

    private

    def self.subscription_exists?
      rds_client.describe_event_subscriptions.inject([]){ |memo, page| memo + page.event_subscriptions_list }.find do |subscription|
        subscription.cust_subscription_id == subscription_name
      end
    end

    def self.subscription_name
      "#{rds_name}-problem-events"
    end

    def self.get_subscription_attributes
      {
        subscription_name: subscription_name,
        sns_topic_arn: get_topic_arn,
        source_type: 'db-instance',
        event_categories: ['failure', 'failover'],
        enabled: true,
        source_ids: [rds_name]
      }
    end

  end
end
