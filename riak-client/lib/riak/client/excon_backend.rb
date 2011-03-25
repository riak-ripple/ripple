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
require 'riak/client/pump'

module Riak
  class Client
    # An HTTP backend for Riak::Client that uses Wesley Beary's Excon
    # HTTP library. Conforms to the Riak::Client::HTTPBackend
    # interface.
    class ExconBackend < HTTPBackend
      def self.configured?
        begin
          require 'excon'
          Excon::VERSION >= "0.5.7"
        rescue LoadError
          false
        end
      end

      private
      def perform(method, uri, headers, expect, data=nil, &block)
        params = {
          :method => method.to_s.upcase,
          :headers => RequestHeaders.new(headers).to_hash,
          :path => uri.path
        }
        params[:query] = uri.query if uri.query
        params[:body] = data if [:put,:post].include?(method)
        params[:idempotent] = (method != :post)

        block = Pump.new(block) if block_given?

        response = connection.request(params, &block)
        if valid_response?(expect, response.status)
          response_headers.initialize_http_header(response.headers)
          result = {:headers => response_headers.to_hash, :code => response.status}
          if return_body?(method, response.status, block_given?)
            result[:body] = response.body
          end
          result
        else
          raise FailedRequest.new(method, expect, response.status, response.headers, response.body)
        end
      end

      def connection
        @connection ||= Excon::Connection.new(root_uri.to_s)
      end
    end
  end
end
