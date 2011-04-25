require 'drb/drb'
DRBURI="druby://localhost:8787"

module DrbMockServer
  extend self

  def start_client
    # JRuby doesn't support fork
    if defined? JRUBY_VERSION
      @server = MockServer.new(2)
      at_exit { @server.stop }
    else
      child_pid = Process.fork do
        start_server
      end
      sleep 1
      at_exit { Process.kill("HUP", child_pid); Process.wait2 }
      DRb.start_service
      @server = DRbObject.new_with_uri(DRBURI)
      sleep 1
    end
    true
  end

  def maybe_start
    start_client unless @server
  end

  def method_missing(meth, *args, &block)
    @server.send(meth, *args, &block)
  end

  def start_server
    server = MockServer.new
    DRb.start_service(DRBURI, server)
    Signal.trap("HUP") { server.stop; exit }
    DRb.thread.join
  end
end
