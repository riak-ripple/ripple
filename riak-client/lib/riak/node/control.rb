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
      ping.chomp == 'pong' || $?.success?
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
      riak 'start'
      wait_for_startup
    end

    # Stops the node
    # @return [String] the output of the 'riak stop' command
    def stop
      riak 'stop'
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
        'pang'
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
      case node
      when Node
        riak_admin 'join', node.name
      else
        riak_admin 'join', name
      end
    end

    # Removes the node from its current cluster, handing off all data.
    # @return [String] the output of the 'riak-admin leave' command
    def leave
      riak_admin 'leave'
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
  end
end
