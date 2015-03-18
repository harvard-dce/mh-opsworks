require 'aws-sdk'
require 'json'
require './lib/cluster/waiters'
require './lib/cluster/configuration_helpers'
require './lib/cluster/naming_helpers'
require './lib/cluster/client_helpers'
require './lib/cluster/base'
require './lib/cluster/app'
require './lib/cluster/deployment'
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
  class StackNotInitialized < StandardError; end
  class NoInstancesOnline < StandardError; end
  class NoRecipesToRun < StandardError; end
end
