namespace :vpc do
  desc 'list vpcs'
  task list: ['cluster:configtest'] do
    Cluster::VPC.all.each do |vpc|
      puts %Q|#{vpc.vpc_id} => #{vpc.cidr_block}, #{vpc.tags}|
    end
  end

  desc 'Initialize a VPC according to your cluster config'
  task init: ['cluster:configtest'] do
    Cluster::VPC.find_or_create
  end
end
