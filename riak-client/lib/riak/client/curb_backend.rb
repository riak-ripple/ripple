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
    # An HTTP backend for Riak::Client that uses the 'curb' library/gem.
    # Conforms to the Riak::Client::HTTPBackend interface.
    class CurbBackend < HTTPBackend
      def self.configured?
        begin
          require 'curb'
          true
        rescue LoadError
          false
        end
      end

      private
      def perform(method, uri, headers, expect, data=nil, &block)
        # Setup
        curl.headers = RequestHeaders.new(headers).to_a
        curl.url = uri.to_s
        response_headers.initialize_http_header(nil)
        if block_given?
          curl.on_body(&Pump.new(block))
        else
          curl.on_body
        end
        # Perform
        case method
        when :post
          data = data.read if data.respond_to?(:read)
          curl.http_post(data)
        when :put
          # Hacks around limitations in curb's PUT semantics
          _headers, curl.headers = curl.headers, {}
          curl.put_data = data
          curl.headers = RequestHeaders.new(curl.headers).to_a + _headers
          curl.http("PUT")
        else
          curl.send("http_#{method}")
        end

        # Verify
        if valid_response?(expect, curl.response_code)
          result = { :headers => response_headers.to_hash, :code => curl.response_code.to_i }
          if return_body?(method, curl.response_code, block_given?)
            result[:body] = curl.body_str
          end
          result
        else
          raise HTTPFailedRequest.new(method, expect, curl.response_code, response_headers.to_hash, curl.body_str)
        end
      end

      def curl
        Thread.current[:curl_easy_handle] ||= Curl::Easy.new.tap do |c|
          configure_ssl(c) if @client.ssl_enabled?

          c.follow_location = false
          c.on_header do |header_line|
            response_headers.parse(header_line)
            header_line.size
          end
        end
      end

      def configure_ssl(curl)
        curl.ssl_verify_peer = @client.ssl_options[:verify_mode] == "peer"
      end
    end
  end
end
