require 'aws-sdk'
require 'json'
require './lib/cluster/waiters'
require './lib/cluster/base'
require './lib/cluster/instance_syncer'
require './lib/cluster/instance'
require './lib/cluster/instances'
require './lib/cluster/layers'
require './lib/cluster/layer'
require './lib/cluster/permissions_syncer'
require './lib/cluster/config'
require './lib/cluster/iam_user'
require './lib/cluster/user'
require './lib/cluster/vpc'
require './lib/cluster/instance_profile'
require './lib/cluster/service_role'
require './lib/cluster/stack'
require './lib/cluster/console'
require './lib/cluster/config_checks/database'
require './lib/cluster/config_checks/json_format'

module Cluster
  class JSONFormatError < StandardError; end
  class VpcConflictsWithAnother < StandardError; end
  class StackConflictsWithAnother < StandardError; end
end
