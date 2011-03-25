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
require 'riak'
begin
  require 'fiber'
rescue LoadError
  require 'riak/util/fiber1.8'
end

module Riak
  class Client
    # @private
    class Pump      
      def initialize(block)
        @fiber = Fiber.new do
          loop do
            block.call Fiber.yield
          end
        end
        @fiber.resume
      end

      def pump(input)
        @fiber.resume input
        input.size if input.respond_to?(:size) # for curb
      end

      def to_proc
        method(:pump).to_proc
      end
    end
  end
end
