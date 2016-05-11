module Cluster
  class SNS < Base
    def self.delete
      topic_arn = get_topic_arn
      delete_subscriptions_for(topic_arn)
      delete_alarms_for_instances
      delete_rds_alarms
      delete_stack_alarms
      sns_client.delete_topic(topic_arn: topic_arn)
    end

    private

    def self.remove_alarms(to_remove)
      if to_remove.any?
        cloudwatch_client.delete_alarms(
          alarm_names: to_remove.map { |alarm| alarm.alarm_name }
        )
      end
    end

    def self.delete_rds_alarms
      to_remove = cloudwatch_client.describe_alarms.inject([]){ |memo, page| memo + page.metric_alarms }.find_all do |alarm|
        alarm.alarm_name.match(/^#{rds_name}/)
      end

      remove_alarms(to_remove)
    end

    def self.delete_stack_alarms
      Cluster::Stack.with_existing_stack do |stack|
        to_remove = []
        stack_id = stack.stack_id
        cloudwatch_client.describe_alarms.inject([]){ |memo, page| memo + page.metric_alarms }.each do |alarm|
          alarm.dimensions.each do |dimension|
            if dimension.name == 'StackId' && stack_id == dimension.value
              to_remove << alarm
            end
          end
        end

        remove_alarms(to_remove)
      end
    end

    def self.delete_alarms_for_instances
      ec2_instance_ids = Cluster::Instances.find_existing.map { |i| i.ec2_instance_id }
      to_remove = []

      cloudwatch_client.describe_alarms.inject([]){ |memo, page| memo + page.metric_alarms }.each do |alarm|
        alarm.dimensions.each do |dimension|
          if dimension.name == 'InstanceId' && ec2_instance_ids.include?(dimension.value)
            to_remove << alarm
          end
        end
      end

      remove_alarms(to_remove)
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

    def self.get_topic_arn
      # create_topic is idempotent
      sns_client.create_topic(name: topic_name).topic_arn
    end
  end
end
