require './lib/cluster'

namespace :vpc do
  desc 'list configured vpcs'
  task list: ['cluster:configtest'] do
    Cluster::VPC.all.each do |vpc|
      puts %Q|#{vpc.vpc_id} => #{vpc.cidr_block}, #{vpc.tags}|
    end
  end

  desc 'Initialize a VPC according to your cluster config'
  task init: ['cluster:configtest'] do
    Cluster::VPC.create_or_initialize
  end
end

namespace :cluster do
  desc 'Sanity check cluster_config.json'
  task :configtest do
    config = Cluster::Config.new
    config.sane?
  end

  desc 'Initialize a matterhorn cluster using the policies in your defined cluster_config.json'
  task init: [:configtest, 'stack:init'] do

  end
end
