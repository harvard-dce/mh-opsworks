namespace :rds do
  desc Cluster::RakeDocs.new('rds:init').desc
  task init: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    from_snapshot = ENV.fetch('from_snapshot', '').strip.downcase
    if ! from_snapshot.empty?
      Cluster::RDS.create_from_snapshot(from_snapshot)
    else
      Cluster::RDS.find_or_create
    end
  end

  desc Cluster::RakeDocs.new('rds:delete').desc
  task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.delete
  end

  desc Cluster::RakeDocs.new('rds:update').desc
  task update: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::RDS.update
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
