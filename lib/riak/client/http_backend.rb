require 'riak'

module Riak
  class Client
    class HTTPBackend
      attr_reader :client

      def initialize(client)
        raise ArgumentError, "Riak::Client instance required" unless Client === client
        @client = client
      end

      def default_headers
        {
          "X-Riak-ClientId" => @client.client_id
        }
      end

      def head(expect, *resource)
        headers = resource.extract_options!
        verify_path!(resource)
        perform(:head, path(*resource), headers, expect)
      end

      def get(expect, *resource, &block)
        headers = resource.extract_options!
        verify_path!(resource)
        perform(:get, path(*resource), headers, expect, &block)
      end

      def put(expect, *resource, &block)
        headers = resource.extract_options!
        uri, data = verify_path_and_body!(resource)
        perform(:put, path(*uri), headers, expect, data, &block)
      end

      def post(expect, *resource, &block)
        headers = resource.extract_options!
        uri, data = verify_path_and_body!(resource)
        perform(:post, path(*uri), headers, expect, data, &block)
      end

      def delete(expect, *resource, &block)
        headers = resource.extract_options!
        verify_path!(resource)
        perform(:delete, path(*resource), headers, expect, &block)
      end

      def root_uri
        URI.join("http://#{@client.host}:#{@client.port}", @client.prefix)
      end

      def path(*segments)
        query = segments.extract_options!.to_param
        root_uri.merge(segments.join("/").gsub(/\/+/, "/").sub(/^\//, '')).tap do |uri|
          uri.query = query if query.present?
        end
      end

      def verify_path_and_body!(args)
        body = args.pop
        begin
          verify_path!(args)
        rescue ArgumentError
          raise ArgumentError, "You must supply both a resource path and a body."
        end

        raise ArgumentError, "Request body must be a string." unless String === body
        [args, body]
      end

      def verify_path!(resource)
        raise ArgumentError, "Resource path too short" if Array(resource).flatten.empty?
      end

      private
      def perform(method, uri, user_headers, expect, data=nil)
        raise NotImplementedError
      end
    end
  end
end
