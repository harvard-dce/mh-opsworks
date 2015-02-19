require 'aws-sdk'
require 'json'
require './lib/cluster/base'
require './lib/cluster/config'
require './lib/cluster/vpc'
require './lib/cluster/stack'

module Cluster
  class JSONFormatError < StandardError; end
  class VpcConflictsWithAnother < StandardError; end
  class StackConflictsWithAnother < StandardError; end
end
