module Cluster
  class SNS < Base
    def self.delete
      topic_arn = get_topic_arn
      delete_subscriptions_for(topic_arn)
      sns_client.delete_topic(topic_arn: topic_arn)
    end

    private

    def self.delete_subscriptions_for(topic_arn, next_token = nil)
      result = sns_client.list_subscriptions_by_topic(
        topic_arn: topic_arn,
        next_token: next_token
      )
      result.subscriptions.each do |subscription|
        sns_client.unsubscribe(subscription_arn: subscription.subscription_arn)
      end
      if result.next_token
        delete_subscriptions_for(topic_arn, result.next_token)
      end
    end

    def self.topic_name
      stack_config[:name].downcase.gsub(/[^a-z\d\-_]/,'_')
    end

    def self.get_topic_arn
      # create_topic is idempotent
      sns_client.create_topic(name: topic_name).topic_arn
    end
  end
end
