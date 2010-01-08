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
    end
  end
end
