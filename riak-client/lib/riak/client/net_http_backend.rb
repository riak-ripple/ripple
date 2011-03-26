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
    # Conforms to the Riak::Client::HTTPBackend interface.
    class NetHTTPBackend < HTTPBackend
      def self.configured?
        begin
          require 'net/http'
          true
        rescue LoadError, NameError
          false
        end
      end

      private
      def perform(method, uri, headers, expect, data=nil) #:nodoc:
        http = Net::HTTP.new(uri.host, uri.port)
        configure_ssl(http) if @client.ssl_enabled?

        request = Net::HTTP.const_get(method.to_s.capitalize).new(uri.request_uri, headers)
        case data
        when String
          request.body = data
        when IO
          request.body_stream = data
        end

        {}.tap do |result|
          http.request(request) do |response|
            if valid_response?(expect, response.code)
              result.merge!({:headers => response.to_hash, :code => response.code.to_i})
              response.read_body {|chunk| yield chunk } if block_given?
              if return_body?(method, response.code, block_given?)
                result[:body] = response.body
              end
            else
              raise Riak::HTTPFailedRequest.new(method, expect, response.code.to_i, response.to_hash, response.body)
            end
          end
        end
      end

      def configure_ssl(http)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL.const_get("VERIFY_#{@client.ssl_options[:verify_mode].upcase}")

        if @client.ssl_options[:pem]
          http.cert = OpenSSL::X510::Certificate.new(@client.ssl_options[:pem])
          http.key  = OpenSSL::PKey::RSA.new(@client.ssl_options[:pem], @client.ssl_options[:pem_password])
        end

        http.ca_file = @client.ssl_options[:ca_file] if @client.ssl_options[:ca_file]

        http.ca_path = @client.ssl_options[:ca_path] if @client.ssl_options[:ca_path]
      end
    end
  end
end
