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
             @block.call obj['keys'].map(&method(:maybe_unescape))
           end
         end
       end
     end
   end
 end

