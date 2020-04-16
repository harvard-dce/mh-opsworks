namespace :rds do
  desc Cluster::RakeDocs.new('rds:init').desc
  task init: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.find_or_create
  end

  desc Cluster::RakeDocs.new('rds:delete').desc
  task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.delete
  end

  desc Cluster::RakeDocs.new('rds:update').desc
  task update: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    update_now = ENV.fetch('update_now', 'false').strip.downcase == 'true'
    Cluster::RDS.update(update_now)
  end

  desc Cluster::RakeDocs.new('rds:stop').desc
  task stop: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.stop
  end

  desc Cluster::RakeDocs.new('rds:start').desc
  task start: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.start
  end
end
