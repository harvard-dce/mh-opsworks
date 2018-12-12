
if Cluster::Base.show_zadara_tasks?
  namespace :zadara do
    desc Cluster::RakeDocs.new('zadara:status').desc
    task status: ['cluster:configtest', 'cluster:config_sync_check'] do
      vpsa = Cluster::Zadara.find_vpsa
      if vpsa
        puts "VPSA '#{vpsa["name"]}' status is '#{vpsa["status"]}'"
      end
    end

    desc Cluster::RakeDocs.new('zadara:hibernate').desc
    task hibernate: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
      Cluster::Zadara.hibernate
    end

    desc Cluster::RakeDocs.new('zadara:restore').desc
    task restore: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
      Cluster::Zadara.restore
    end
  end
end
