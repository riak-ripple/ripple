# Copyright 2010-2011 Sean Cribbs and Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'riak/util/escape'
require 'riak/json'

module Riak
   class Client
     class HTTPBackend
       # @private
       class KeyStreamer
         include Util::Escape

         def initialize(block)
           @buffer = ""
           @block = block
         end

         def accept(chunk)
           @buffer << chunk
           consume
         end

         def to_proc
           method(:accept).to_proc
         end

         private
         def consume
           while @buffer =~ /\}\{/
             stream($~.pre_match + '}')
             @buffer = '{' + $~.post_match
           end
         end

         def stream(str)
           obj = JSON.parse(str) rescue nil
           if obj && obj['keys']
             @block.call obj['keys'].map(&method(:unescape))
           end
         end
       end
     end
   end
 end

