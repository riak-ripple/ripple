require 'drb/drb'
DRBURI="druby://localhost:8787"

module DrbMockServer
  extend self
  def start_server
    server = MockServer.new
    DRb.start_service(DRBURI, server)
    Signal.trap("HUP") { server.stop; exit }
    DRb.thread.join
  end

  def start_client
    child_pid = fork do
      start_server
    end
    sleep 1
    at_exit { Process.kill("HUP", child_pid); Process.wait2 }
    DRb.start_service
    @server = DRbObject.new_with_uri(DRBURI)
    true
  end

  def maybe_start
    start_client unless @server
  end

  def method_missing(meth, *args, &block)
    @server.send(meth, *args, &block)
  end
end
