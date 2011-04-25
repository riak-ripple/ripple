
require 'riak/failed_request'
require 'riak/client/http_backend'
require 'riak/client/http_backend/request_headers'
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
        configure_ssl if @client.ssl_enabled?

        params = {
          :method => method.to_s.upcase,
          :headers => RequestHeaders.new(headers).to_hash,
          :path => uri.path
        }
        params[:query] = uri.query if uri.query
        params[:body] = data if [:put,:post].include?(method)
        params[:idempotent] = (method != :post)

        if block_given?
          pump = Pump.new(block)
          # Later versions of Excon pass multiple arguments to the block
          block = lambda {|*args| pump.pump(args.first) }
        end

        response = connection.request(params, &block)
        response_headers.initialize_http_header(response.headers)

        if valid_response?(expect, response.status)
          result = {:headers => response_headers.to_hash, :code => response.status}
          if return_body?(method, response.status, block_given?)
            result[:body] = response.body
          end
          result
        else
          raise HTTPFailedRequest.new(method, expect, response.status, response_headers.to_hash, response.body)
        end
      end

      def connection
        @connection ||= Excon::Connection.new(root_uri.to_s)
      end

      def configure_ssl
        Excon.ssl_verify_peer = @client.ssl_options[:verify_mode].to_s === "peer"
        Excon.ssl_ca_path     = @client.ssl_options[:ca_path] if @client.ssl_options[:ca_path]
      end
    end
  end
end
