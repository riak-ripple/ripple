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
    end
  end
end
