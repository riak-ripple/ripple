# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# Based on code from Rob Styles and Chris Tierney found at:
#   http://dynamicorange.com/2009/02/18/ruby-mock-web-server/
require 'rack'

class MockServer
  attr_accessor :port
  
  def initialize(pause = 1)
    self.port = 4000 + rand(61535)
    @block = nil
    @parent_thread = Thread.current
    @thread = Thread.new do
      Rack::Handler::WEBrick.run(self, :Port => port, :AccessLog => [], :Logger => NullLogger.new, :Host => '127.0.0.1')
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
