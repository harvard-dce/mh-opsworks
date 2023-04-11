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

  desc Cluster::RakeDocs.new('rds:upgrade57').desc
  task upgrade57: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    upgrade_step = ENV.fetch('upgrade_step', 'pre').strip.downcase
    unless ['pre','remove', 'ids'].include?(upgrade_step)
      puts %Q|`upgrade_step` argument must be one of "pre", "remove" or "ids"|
      exit 1
    end
    Cluster::RDS.upgrade57(upgrade_step)
  end
end
