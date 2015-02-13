require 'aws-sdk'
require 'json'
require './lib/cluster/base'
require './lib/cluster/config'
require './lib/cluster/vpc'

module Cluster
  class JSONFormatError < StandardError; end
  class VpcConflictsWithAnother < StandardError; end
end
