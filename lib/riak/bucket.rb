module Riak
  # Represents and encapsulates operations on a Riak bucket.  You may retrieve a bucket
  # using {Client#bucket}, or create it manually and retrieve its meta-information later.
  class Bucket
    # @return [Hash] Internal Riak bucket properties.
    attr_reader :props

    # @return [Array<String>] Keys in this bucket
    attr_reader :keys

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
      return self unless response.try(:[], :headers).try(:[],'content-type').try(:first) =~ /json$/
      payload = JSON.parse(response[:body])
      @keys = payload['keys'] if payload['keys']
      @props = payload['props'] if payload['props']
      self
    end
  end
end
