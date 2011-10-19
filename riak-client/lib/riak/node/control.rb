require 'riak/node/console'
require 'riak/util/tcp_socket_extensions'

module Riak
  class Node
    # Regexp for parsing riak-admin status output. Takes into account
    # the minor bug fixed by {https://github.com/basho/riak_kv/pull/134}
    # and multiline output used when lists of things grow long.
    STATS_REGEXP = /^([^:\n]+)\s:\s((?:.*)(?:\n\s+[^\n]+)*)/

    # Is the node running?
    # @return [true, false] If the node is running
    def started?
      pinged = ping
      pinged.strip =~ /pong/ || pinged.strip !~ /Node '[^']+' not responding to pings/
    end

    # Is the node stopped? (opposite of {#started?}).
    # @return [true, false] If the node is stopped
    # @see #started?
    def stopped?
      !started?
    end

    # Starts the node.
    # @return [String] the output of the 'riak start' command
    def start
      res = riak 'start'
      wait_for_startup
      res
    end

    # Stops the node
    # @return [String] the output of the 'riak stop' command
    def stop
      res = riak 'stop'
      wait_for_shutdown
      res
    end

    # Restarts the node
    # @return [String] the output of the 'riak restart' command
    def restart
      riak 'restart'
    end

    # Reboots the node
    # @return [String] the output of the 'riak reboot' command
    def restart
      riak 'reboot'
    end

    # Pings the node
    # @return [String] the output of the 'riak ping' command
    def ping
      begin
        riak 'ping'
      rescue SystemCallError
        # If the control script doesn't exist or has the wrong
        # permissions, we should still return something sane so we can
        # do the right thing.
        "Node '#{name}' not responding to pings."
      end
    end

    # Attach to the node's console via the pipe.
    # @return [Riak::Node::Console] A console manager for sending
    #    commands to the Riak node
    # @see #with_console
    def attach
      Console.open self
    end

    # Execute the block against the Riak node's console.
    # @yield [console] A block of commands to be run against the console
    # @yieldparam [Riak::Node::Console] console A console manager for
    #    sending commands to the Riak node
    def with_console
      begin
        console = attach
        yield console
      ensure
        console.close if console
      end
    end

    # Joins the node to another node to create a cluster.
    # @return [String] the output of the 'riak-admin join' command
    def join(node)
      node = node.name if Node === node
      riak_admin 'join', node
    end

    # Removes this node from its current cluster, handing off all data.
    # @return [String] the output of the 'riak-admin leave' command
    def leave
      riak_admin 'leave'
    end

    # Forcibly removes a node from the current cluster without
    # invoking handoff.
    # @return [String] the output of the 'riak-admin remove <node>'
    #   command
    def remove(node)
      node = node.name if Node === node
      riak_admin 'remove', node
    end

    # Captures the status of the node.
    # @return [Hash] a collection of information about the node
    def status
      output = riak_admin 'status'
      if $?.success?
        result = {}
        Hash[output.scan(STATS_REGEXP)]
      end
    end

    # Detects whether the node's cluster has converged on the ring.
    # @return [true,false] whether the ring is stable
    def ringready?
      output = riak_admin 'ringready'
      output =~ /^TRUE/ || $?.success?
    end

    # Lists riak_core applications that have registered as available,
    # e.g.  ["riak_kv", "riak_search", "riak_pipe"]
    # @return [Array<String>] a list of running services
    def services
      output = riak_admin 'services'
      if $?.success?
        output.strip.match(/^\[(.*)\]$/)[1].split(/,/)
      else
        []
      end
    end

    # Forces the node to restart/reload its JavaScript VMs,
    # effectively reloading any user-provided code.
    def js_reload
      riak_admin 'js_reload'
    end

    # Provides the status of members of the ring.
    # @return [Hash] a collection of stats about ring members
    def member_status
      output = riak_admin 'member_status'
      result = {}
      if $?.success?
        output.each_line do |line|
          next if line =~ /^(?:[=-]|Status)+/  # Skip the pretty headers
          if line =~ %r{^Valid:(\d+) / Leaving:(\d+) / Exiting:(\d+) / Joining:(\d+) / Down:(\d+)}
            result.merge!(:valid =>   $1.to_i,
                          :leaving => $2.to_i,
                          :exiting => $3.to_i,
                          :joining => $4.to_i,
                          :down =>    $5.to_i)
          else
            result[:members] ||= {}
            status, ring, pending, node = line.split(/\s+/)
            node = $1 if node =~ /^'(.*)'$/
            ring = $1.to_f if ring =~ /(\d+\.\d+)%/
            result[:members][node] = {
              :status => status,
              :ring => ring,
              :pending => (pending == '--') ? 0 : pending.to_i
            }
          end
        end
      end
      result
    end

    # @return [Array<String>] a list of node names that are also
    #   members of this node's cluster, and empty list if the
    #   {#member_status} fails or no other nodes are present
    def peers
      all_nodes = member_status[:members] && member_status[:members].keys.reject {|n| n == name }
      all_nodes || []
    end

    protected
    # Runs a command using the 'riak' control script.
    def riak(*commands)
      `#{control_script} #{commands.join(' ')} 2>&1`
    end

    # Runs a command using the 'riak-admin' script.
    def riak_admin(*commands)
      `#{admin_script} #{commands.join(' ')} 2>&1`
    end

    # Waits for the HTTP port to become available, which is a better
    # indication of readiness than the start script finishing.
    def wait_for_startup
      TCPSocket.wait_for_service_with_timeout(:host => http_ip,
                                              :port => http_port,
                                              :timeout => 10)
    end

    def wait_for_shutdown
      TCPSocket.wait_for_service_termination_with_timeout(:host => http_ip,
                                                          :port => http_port,
                                                          :timeout => 10)
    end
  end
end
