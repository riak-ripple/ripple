module Riak
  # Represents and encapsulates operations on a Riak bucket.  You may retrieve a bucket
  # using {Client#bucket}, or create it manually and retrieve its meta-information later.
  class Bucket
    # @return [Riak::Client] the associated client
    attr_reader :client

    # @return [String] the bucket name
    attr_reader :name

    # @return [Hash] Internal Riak bucket properties.
    attr_reader :props

    # Create a Riak bucket manually.
    # @param [Client] client the {Riak::Client} for this bucket
    # @param [String] name the name of the bucket
    def initialize(client, name)
      raise ArgumentError, "invalid argument #{client} is not a Riak::Client" unless Client === client
      raise ArgumentError, "invalid argument #{name} is not a String" unless String === name
      @client, @name = client, name
    end

    # Load information for the bucket from a response given by the {Riak::Client::HTTPBackend}.
    # @param [Hash] response a response from {Riak::Client::HTTPBackend}
    # @return [Bucket] self
    def load(response={})
      unless response.try(:[], :headers).try(:[],'content-type').try(:first) =~ /json$/
        raise Riak::InvalidResponse.new({"content-type" => ["application/json"]}, response[:headers], "while loading bucket '#{name}'")
      end
      payload = JSON.parse(response[:body])
      @keys = payload['keys'] if payload['keys']
      @props = payload['props'] if payload['props']
      self
    end

    # Accesses or retrieves a list of keys in this bucket.
    # If a block is given, keys will be streamed through
    # the block (useful for large buckets). When streaming,
    # results of the operation will not be retained.
    # @param [Hash] options extra options
    # @yield [Array<String>] a list of keys from the current chunk
    # @option options [true] :reload (nil) If present, will force reloading of the bucket's keys from Riak
    # @return [Array<String>] Keys in this bucket
    def keys(options={})
      if block_given?
        client.http.get(200, name, {:props => false}, {}) do |chunk|
          obj = JSON.parse(chunk) rescue {}
          yield obj['keys'] if obj['keys']
        end
      elsif @keys.nil? || options[:reload]
        response = client.http.get(200, name, {:props => false}, {})
        load(response)
      end
      @keys
    end

    # Sets internal properties on the bucket
    # Note: this results in a request to the Riak server
    # @param [Hash] propertiess new properties for the bucket
    # @return [Hash] the properties that were accepted
    # @raise [FailedRequest] if the new properties were not accepted by the Riak server
    def props=(properties)
      raise ArgumentError, "properties must be a Hash" unless Hash === properties
      body = {'props' => properties}.to_json
      client.http.put(204, name, body, {"Content-Type" => "application/json"})
      @props = properties
    end
  end
end
