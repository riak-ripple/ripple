require 'riak/failed_request'
require 'riak/client/http_backend'
require 'riak/client/http_backend/request_headers'

module Riak
  class Client
    # An HTTP backend for Riak::Client that uses Wesley Beary's Excon
    # HTTP library. Conforms to the Riak::Client::HTTPBackend
    # interface.
    class ExconBackend < HTTPBackend
      def self.configured?
        begin
          require 'excon'
          Client::NETWORK_ERRORS << Excon::Errors::SocketError
          Client::NETWORK_ERRORS.uniq!
          Excon::VERSION >= "0.5.7" && patch_excon
        rescue LoadError
          false
        end
      end

      # Adjusts Excon's connection collection to allow multiple
      # connections to the same host from the same Thread. Instead we
      # use the Riak::Client::Pool to segregate connections.
      # @note This can be changed when Excon has a proper pool of its own.
      def self.patch_excon
        unless defined? @@patched
          ::Excon::Connection.class_eval do
            def sockets
              @sockets ||= {}
            end
          end
        end
        @@patched = true
      end

      def teardown
        connection.reset
      end

      private
      def perform(method, uri, headers, expect, data=nil, &block)
        configure_ssl if @node.ssl_enabled?

        params = {
          :method => method.to_s.upcase,
          :headers => RequestHeaders.new(headers).to_hash,
          :path => uri.path
        }
        params[:query] = uri.query if uri.query
        params[:body] = data if [:put,:post].include?(method)
        params[:idempotent] = (method != :post)

        # Later versions of Excon pass multiple arguments to the block
        block = lambda {|*args| yield args.first } if block_given?

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
        Excon.ssl_verify_peer = @node.ssl_options[:verify_mode].to_s === "peer"
        Excon.ssl_ca_path     = @node.ssl_options[:ca_path] if @node.ssl_options[:ca_path]
      end
    end
  end
end
