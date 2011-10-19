require 'pathname'
require 'riak/node'
require 'riak/util/translation'

module Riak
  # Generates and controls a cluster of {Riak::Node} instances for use
  # in development or testing on a single machine.
  class Cluster
    include Util::Translation
    # @return [Array<Node>] the member Nodes of this cluster
    attr_reader :nodes

    # @return [Hash] the cluster configuration
    attr_reader :configuration

    # @return [Pathname] the root directory of the cluster
    attr_reader :root

    # Creates a {Cluster} of {Node}s.
    # @param [Hash] config the configuration for the cluster
    # @option config [Fixnum] :count the number of nodes to create
    # @option config [String] :source path to the Riak bin/ directory.
    #   See {Node#source}.
    # @option config [String] :root path to where the nodes will be
    #   generated.
    # @option config [Fixnum] :min_port the base port number from
    #   which nodes will claim IP ports for HTTP, PB, handoff.
    def initialize(config={})
      raise ArgumentError, t('source_and_root_required') unless config[:source] && config[:root]
      @configuration = config
      @count = config.delete(:count) || 4
      @min_port = config.delete(:min_port) || 9000
      @root = Pathname.new(config.delete(:root))
      @nodes = []
      cookie = "#{rand(100000).to_s}_#{rand(1000000).to_s}"
      @count.times do |i|
        nodes << Riak::Node.new(config.merge(:min_port => @min_port + (i * 3),
                                             :root => @root + (i+1).to_s,
                                             :cookie => cookie))
      end
    end

    # @return [true,false] whether the cluster has been created
    def exist?
      root.directory? && nodes.all? {|n| n.exist? }
    end

    # Generates all nodes in the cluster.
    def create
      unless exist?
        root.mkpath unless root.exist?
        nodes.each {|n| n.create }
      end
    end

    # Removes all nodes in the cluster and the root, and freezes the
    # object.
    def destroy
      nodes.each {|n| n.destroy }
      root.rmtree if root.exist?
      freeze
    end

    # Removes and recreates the cluster.
    def recreate
      stop unless stopped?
      root.rmtree if root.exist?
      create
    end

    # Drops all data from the cluster without destroying the nodes.
    def drop
      nodes.each {|n| n.drop }
    end

    # Starts all nodes in the cluster.
    def start
      nodes.each {|n| n.start }
    end

    # Stops all nodes in the cluster.
    def stop
      nodes.each {|n| n.stop }
    end

    # Restarts all nodes in the cluster (without exiting the Erlang
    # runtime)
    def restart
      nodes.each {|n| n.restart }
    end

    # Reboots all nodes in the cluster
    def reboot
      nodes.each {|n| n.reboot }
    end

    # Forces the cluster nodes to restart/reload their JavaScript VMs,
    # effectively reloading any user-provided code.
    def js_reload
      nodes.each {|n| n.js_reload }
    end

    # Attaches to the console on all nodes, returning a list of
    # {Riak::Node::Console} objects.
    # @return [Array<Riak::Node::Console>] consoles for all running
    #   nodes, with nil for nodes that aren't running or otherwise
    #   fail to connect
    def attach
      nodes.map do |n|
        begin
          n.attach
        rescue ArgumentError, SystemCallError
          nil
        end
      end
    end

    # Executes the given block on each node against the node's
    # console. You could use this to send Erlang commands to all nodes
    # in the cluster.
    # @yield [console] A block of commands to be run against the
    #   console
    # @yieldparam [Riak::Node::Console] console A console manager for
    #   sending commands to the current node in the iteration
    def with_console(&block)
      nodes.each do |n|
        n.with_console(&block)
      end
    end

    # Is the cluster started?
    def started?
      nodes.all? {|n| n.started? }
    end

    # Is the cluster stopped?
    def stopped?
      nodes.all? {|n| n.stopped? }
    end

    # Joins the nodes together into a cluster.
    # @note This method relies on cluster membership changes present
    #   in the 1.0 series of Riak, and is NOT safe on 0.14 and
    #   earlier.
    def join
      claimant = nodes.first.name # Not really the claimant, just a
                                  # node to join to
      nodes[1..-1].each {|n| n.join(claimant) unless n.peers.include?(claimant) }
    end
  end
end
