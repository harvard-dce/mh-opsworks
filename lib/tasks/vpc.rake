namespace :vpc do
  desc 'list vpcs'
  task list: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::VPC.all.each do |vpc|
      puts %Q|#{vpc.vpc_id} => #{vpc.cidr_block}, #{vpc.tags}|
    end
  end

  desc 'Initialize a VPC according to your cluster config'
  task init: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::VPC.find_or_create
  end

  desc 'Remove the configured VPC'
  task delete: ['cluster:configtest', 'cluster:config_sync_check'] do
    Cluster::VPC.delete
  end
end
