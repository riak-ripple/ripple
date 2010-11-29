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
    # An HTTP backend for Riak::Client that uses Wesley Beary's Excon
    # HTTP library. Comforms to the Riak::Client::HTTPBackend
    # interface.
    class ExconBackend < HTTPBackend
      def self.configured?
        begin
          require 'excon'
          true
        rescue LoadError
          false
        end
      end

      private
      def perform(method, uri, headers, expect, data=nil, &block)
        params = {:headers => RequestHeaders.new(headers)}
        params[:body] = data if [:put,:post].include?(method)
        # Excon currently doesn't properly handle string query
        # segment. Why?
        if uri.query
          q = uri.query.split('&').map {|kv| kv.split('=') }
          uri.query = nil
          params[:query] = {}
          q.each do |pair|
            params[:query][pair[0]] ||= []
            params[:query][pair[0]] << pair[1]
          end
        end
        # params[:idempotent] = (method != :post)
        response = Excon.send(method, uri.to_s, params, &block)
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

      # Excon uses for..in syntax to emit headers, but we still want
      # to split them on 8KB boundaries.
      class RequestHeaders < Riak::Util::Headers
        alias each each_capitalized

        def initialize(hash)
          initialize_http_header(hash)
        end
      end
    end
  end
end
