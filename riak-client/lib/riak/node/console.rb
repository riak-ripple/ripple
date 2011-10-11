require 'expect'
require 'pathname'
require 'riak/util/translation'

if ENV['DEBUG_RIAK_CONSOLE']
  $expect_verbose = true
end

module Riak
  class Node
    # Eases working with the Erlang console when attached to the Riak
    # node.
    class Console
      include Util::Translation

      # @return [String] the name of the connected node
      attr_accessor :nodename

      # Opens a {Console} by connecting to the node.
      # @return [Console] the opened console
      def self.open(node)
        new node.pipe, node.name
      end

      # Creates a {Console} from the IO pipes connected to the node.
      # @param [String,Pathname] pipedir path to the pipes opened by
      #   run_erl
      # @param [String] nodename the name of the node the Console will
      #   be attached to
      def initialize(pipedir, nodename)
        @nodename = nodename
        @mutex = Mutex.new
        @winch = Signal.trap("WINCH", &method(:handle_winch))
        @prompt = /\(#{Regexp.escape(nodename)}\)\d+>\s*/
        pipedir = Pathname(pipedir)
        pipedir.children.each do |path|
          if path.pipe?
            if path.fnmatch("*.r") # Read pipe
              # debug "Found read pipe: #{path}"
              @rfile ||= path
            elsif path.fnmatch("*.w") # Write pipe
              # debug "Found write pipe: #{path}"
              @wfile ||= path
            end
          else
            debug "Non-pipe found! #{path}"
          end
        end
        raise ArgumentError, t('no_pipes', :path => pipedir.to_s) if [@rfile, @wfile].any? {|p| p.nil? }
        # We have to open the read pipe AFTER we have sent some data
        # to the write pipe, otherwise JRuby hangs.
        begin
          debug "Opening write pipe."
          @w = open_write_pipe
          @w.sync = true
          debug "Opening read pipe."
          @r = open_read_pipe
          command 'ok.'
          debug "Initialized console: #{@r.inspect} #{@w.inspect}"
        rescue => e
          debug e.message
          close
          raise t('no_pipes', :path => pipedir.to_s) + "[ #{e.message} ]"
        end
      end

      # Sends an Erlang command to the console
      # @param [String] cmd an Erlang expression to send to the node
      def command(cmd)
        @mutex.synchronize do
          begin
            debug "Sending command #{cmd.inspect}"
            @w.print "#{cmd}\n"
            wait_for_erlang_prompt
          rescue SystemCallError
            close
          end
        end
      end

      # Detects whether the console connection is still open, that is,
      # if the node hasn't disconnected from the other side of the
      # pipe.
      def open?
        (@r && !@r.closed?) && (@w && !@w.closed?)
      end

      # Scans the output of the console until an Erlang shell prompt
      # is found. Called by {#command} to ensure that the submitted
      # command succeeds.
      def wait_for_erlang_prompt
        wait_for @prompt
      end

      # Scans the output of the console for the given pattern.
      # @param [String, Regexp] pattern the pattern to scan for
      def wait_for(pattern)
        debug "Scanning for #{pattern.inspect}"
        @r.expect(pattern)
      end

      # Closes the console by detaching from the pipes.
      def close
        @r.close if @r && !@r.closed?
        @w.close if @w && !@w.closed?
        Signal.trap("WINCH", @winch)
        freeze
      end

      protected
      # Handles the "window change" signal by faking it.
      def handle_winch
        debug "WINCHED!"
        @w.print "\033_winsize=80,26\033\\"
        Signal.trap("WINCH", &method(:handle_winch))
      end

      def debug(msg)
        $stderr.puts msg if ENV["DEBUG_RIAK_CONSOLE"]
      end

      def open_write_pipe
        if defined?(::Java)
          java.io.FileOutputStream.new(@wfile.to_s).to_io
        else
          @wfile.open(File::WRONLY|File::NONBLOCK)
        end
      end

      def open_read_pipe
        if defined?(::Java)
          IO.popen("cat #{@rfile}", "rb")
        else
          @rfile.open(File::RDONLY|File::NONBLOCK)
        end
      end
    end
  end
end
