namespace :rds do
  desc Cluster::RakeDocs.new('rds:create_event_subscriptions').desc
  task create_event_subscriptions: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::RDS::EventSubscriptionCreator.create
    puts 'Event subscriptions being created.'
  end

  desc Cluster::RakeDocs.new('rds:hibernate').desc
  task hibernate: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.hibernate
  end

  desc Cluster::RakeDocs.new('rds:restore').desc
  task restore: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.restore
  end
end
