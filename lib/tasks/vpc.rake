namespace :vpc do
  desc Cluster::RakeDocs.new('vpc:list').desc
  task list: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::VPC.all.each do |vpc|
      puts %Q|#{vpc.vpc_id}	#{vpc.cidr_block}	#{vpc.tags}|
    end
  end

  desc Cluster::RakeDocs.new('vpc:init').desc
  task init: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::VPC.find_or_create
  end

  desc Cluster::RakeDocs.new('vpc:delete').desc
  task delete: ['cluster:configtest', 'cluster:config_sync_check', 'cluster:production_failsafe'] do
    Cluster::VPC.delete
  end
end
