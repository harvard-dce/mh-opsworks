module Cluster
  class SNS < Base
    def self.delete
      topic_arn = get_topic_arn
      delete_subscriptions_for(topic_arn)
      delete_alarms_for_instances
      sns_client.delete_topic(topic_arn: topic_arn)
    end

    private

    def self.delete_alarms_for_instances
      opsworks_instance_ids = Cluster::Instances.find_existing.map { |i| i.instance_id }
      to_remove = []

      cloudwatch_client.describe_alarms.each do |page|
        page.metric_alarms.each do |alarm|
          alarm.dimensions.each do |dimension|
            if dimension.name == 'InstanceId' && opsworks_instance_ids.include?(dimension.value)
              to_remove << alarm
            end
          end
        end
      end

      if to_remove.any?
        cloudwatch_client.delete_alarms(
          alarm_names: to_remove.map { |alarm| alarm.alarm_name }
        )
      end
    end

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
