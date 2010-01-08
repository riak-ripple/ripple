# -*- coding: utf-8 -*-
require 'rack'
#
## Bring up server in a new thread (do once?):
# @mock_server = MockServer.new(4000, 0.5)
#
#
## Pull down server:
# @mock_server.stop
#
#
## Expectations (rspec example):
# request_received = false
# @mock_server.attach do |env|
# request_received = true
# env['REQUEST_METHOD'].should == ‘POST’
# env['PATH_INFO'].should == ‘/foo’
# [ 200, { 'Content-Type' => 'text/plain', 'Content-Length' => '40' }, [ 'This gets returned from the HTTP request' ]]
# end
# request_received.should be_true
# my_code_that_should_make_post_request # to http://localhost:4000/foo
#
#
## After each test:
# @mock_server.detach
#
#
class MockServer
  def initialize(port = 4000, pause = 1)
    @block = nil
    @parent_thread = Thread.current
    @thread = Thread.new do
      Rack::Handler::WEBrick.run(self, :Port => port, :AccessLog => [], :Logger => NullLogger.new)
    end
    sleep pause # give the server time to fire up… YUK!
  end

  def stop
    Thread.kill(@thread)
  end

  def attach(&block)
    @block = block
  end

  def detach()
    @block = nil
  end

  def call(env)
    begin
      raise "Specify a handler for the request using attach(block), the block should return a valid rack response and can test expectations" unless @block
      @block.call(env)
    rescue Exception => e
      @parent_thread.raise e
      [ 500, { 'Content-Type' => 'text/plain', 'Content-Length' => '13' }, [ 'Bad test code' ]]
    end
  end

  class NullLogger
    def fatal(msg) end
    def error(msg) end
    def warn(msg)  end
    def info(msg)  end
    def debug(msg) end
  end
end
