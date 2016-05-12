namespace :rds do
  desc Cluster::RakeDocs.new('rds:create_event_subscriptions').desc
  task create_event_subscriptions: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::RDS::EventSubscriptionCreator.create
    puts 'Event subscriptions being created.'
  end
end
