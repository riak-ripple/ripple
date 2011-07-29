require 'open3'
require 'expect'
if ENV['DEBUG_RIAK_CONSOLE']                                        
  $expect_verbose = true
end

module Riak
  class Node
    # Eases working with the Erlang console when attached to the Riak
    # node.
    class Console
      # Opens a Console by running the given command using popen3.
      def self.open(command)
        new *Open3.popen3(command)
      end
      
      # Creates a Console from the IO streams connected to the node.
      def initialize(stdin, stdout, stderr, thr=nil)
        @cin, @cout, @cerr, @cthread = stdin, stdout, stderr, thr
        @mutex = Mutex.new
        wait_for_erlang_prompt
      end

      # Sends an Erlang command to the console
      def command(cmd)
        @mutex.synchronize do
          begin
            @cin.puts cmd
            wait_for_erlang_prompt
          rescue Errno::EPIPE
            close            
          end
        end
      end
            
      # Scans the output of the console until an Erlang shell prompt
      # is found. Called by {#command} to ensure that the submitted
      # command succeeds.
      def wait_for_erlang_prompt(nodename=nil)
        @cin.flush
        if nodename
          @cout.expect(/\(#{Regexp.escape(nodename)})\d+>/)
        else          
          @cout.expect(/\(.+?\)\d+>/)
        end
      end

      def close
        [@cin, @cout, @cerr].each {|io| io.close unless io.closed? }
        # Ruby 1.9 popen3 returns a Thread to manage the subprocess,
        # we need to join it.
        @cthread.join if @cthread && @cthread.alive?
        freeze
      end
    end
  end
end
