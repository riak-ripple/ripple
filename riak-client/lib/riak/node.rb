require 'riak/util/translation'
require 'riak/node/defaults'
require 'riak/node/configuration'
require 'riak/node/generation'
require 'riak/node/control'
require 'riak/node/version'
require 'riak/node/log'

module Riak
  # A Node encapsulates the generation and management of standalone
  # Riak nodes. It is used by the {TestServer} to start and manage an
  # in-memory node for supporting integration test suites.
  class Node
    include Util::Translation

    # Creates a new Riak node. Unlike {#new}, this will also generate
    # the node if it does not exist on disk.  Equivalent to {::new}
    # followed by {#create}.
    # @see #new
    def self.create(configuration={})
      new(configuration).tap do |node|
        node.create
      end
    end

    # Creates the template for a Riak node. To generate the node after
    # initialization, use {#create}.
    def initialize(configuration={})
      set_defaults
      configure configuration
    end

    protected
    def debug(msg)
      $stderr.puts msg if ENV["DEBUG_RIAK_NODE"]
    end
  end
end
