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

module Riak
  class Client
    # Uses the Ruby standard library Net::HTTP to connect to Riak.
    # We recommend using the CurbBackend, which will
    # be preferred when the 'curb' library is available.
    # Conforms to the Riak::Client::HTTPBackend interface.
    class NetHTTPBackend < HTTPBackend
      private
      def perform(method, uri, headers, expect, data=nil) #:nodoc:
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send(method, *([uri.request_uri, data, headers].compact))
          if response.code.to_i == expect.to_i
            result = {:headers => response.to_hash}
            unless method == :head || [204, 304].include?(response.code.to_i)
              if block_given?
                response.read_body {|chunk| yield chunk }
              else
                result[:body] = response.body
              end
            end
            result
          else
            raise FailedRequest.new(method, expect, response.code, response.to_hash, response.body)
          end
        end
      end
    end
  end
end
