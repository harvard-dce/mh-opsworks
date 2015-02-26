require 'aws-sdk'
require 'json'
require './lib/cluster/base'
require './lib/cluster/permissions_syncer'
require './lib/cluster/config'
require './lib/cluster/iam_user'
require './lib/cluster/user'
require './lib/cluster/vpc'
require './lib/cluster/instance_profile'
require './lib/cluster/service_role'
require './lib/cluster/stack'
require './lib/cluster/console'

module Cluster
  class JSONFormatError < StandardError; end
  class VpcConflictsWithAnother < StandardError; end
  class StackConflictsWithAnother < StandardError; end
end
