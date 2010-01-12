require 'riak'

module Riak
  # A client connection to Riak.
  class Client
    autoload :FailedRequest,  "riak/client/failed_request"
    autoload :HTTPBackend,    "riak/client/http_backend"
    autoload :NetHTTPBackend, "riak/client/net_http_backend"
    autoload :CurbBackend,    "riak/client/curb_backend"

    # When using integer client IDs, the exclusive upper-bound of valid values.
    MAX_CLIENT_ID = 4294967296

    # Regexp for validating hostnames, lifted from uri.rb in Ruby 1.8.6
    HOST_REGEX = /^(?:(?:(?:[a-zA-Z\d](?:[-a-zA-Z\d]*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:[-a-zA-Z\d]*[a-zA-Z\d])?)\.?|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\[(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|(?:(?:[a-fA-F\d]{1,4}:)*[a-fA-F\d]{1,4})?::(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))?)\])$/n

    # @return [String] The host or IP address for the Riak endpoint
    attr_reader :host

    # @return [Fixnum] The port of the Riak HTTP endpoint
    attr_reader :port

    # @return [String] The internal client ID used by Riak to route responses
    attr_reader :client_id

    # @return [String] The URL path prefix to the "raw" HTTP endpoint
    attr_accessor :prefix

    # Creates a client connection to Riak
    # @param [Hash] options configuration options for the client
    # @option options [String] :host ('127.0.0.1') The host or IP address for the Riak endpoint
    # @option options [Fixnum] :port (8098) The port of the Riak HTTP endpoint
    # @option options [String] :prefix ('/raw/') The URL path prefix to the "raw" HTTP endpoint
    # @option options [Fixnum, String] :client_id (rand(MAX_CLIENT_ID)) The internal client ID used by Riak to route responses
    # @raise [ArgumentError] raised if any options are invalid
    def initialize(options={})
      options.assert_valid_keys(:host, :port, :prefix, :client_id)
      self.host      = options[:host]      || "127.0.0.1"
      self.port      = options[:port]      || 8098
      self.client_id = options[:client_id] || make_client_id
      self.prefix    = options[:prefix]    || "/raw/"
      raise ArgumentError, "You must specify a host and port, or use the defaults of 127.0.0.1:8098" unless @host && @port
    end

    # Set the client ID for this client. Must be a string or Fixnum value 0 =< value < MAX_CLIENT_ID.
    # @param [String, Fixnum] value The internal client ID used by Riak to route responses
    # @raise [ArgumentError] when an invalid client ID is given
    # @return [String] the assigned client ID
    def client_id=(value)
      @client_id = case value
                   when 0...MAX_CLIENT_ID
                     b64encode(value)
                   when String
                     value
                   else
                     raise ArgumentError, "Invalid client ID, must be a string or between 0 and #{MAX_CLIENT_ID}"
                   end
    end

    # Set the hostname of the Riak endpoint. Must be an IPv4, IPv6, or valid hostname
    # @param [String] value The host or IP address for the Riak endpoint
    # @raise [ArgumentError] if an invalid hostname is given
    # @return [String] the assigned hostname
    def host=(value)
      raise ArgumentError, "host must be a valid hostname" unless String === value && value.present? && value =~ HOST_REGEX
      @host = value
    end

    # Set the port number of the Riak endpoint. This must be an integer between 0 and 65535.
    # @param [Fixnum] value The port number of the Riak endpoint
    # @raise [ArgumentError] if an invalid port number is given
    # @return [Fixnum] the assigned port number
    def port=(value)
      raise ArgumentError, "port must be an integer between 0 and 65535" unless (0..65535).include?(value)
      @port = value
    end

    # Automatically detects and returns an appropriate HTTP backend.
    # The HTTP backend is used internally by the Riak client, but can also
    # be used to access the server directly.
    # @return [HTTPBackend] the HTTP backend for this client
    def http
      @http ||= begin
                  require 'curb'
                  CurbBackend.new(self)
                rescue LoadError, NameError
                  warn "curb library not found! Please `gem install curb` for better performance."
                  NetHTTPBackend.new(self)
                end
    end

    # Retrieves a bucket from Riak.
    # @param [String] bucket the bucket to retrieve
    # @param [Hash] options options for retrieving the bucket
    # @option options [true,false] :keys (true) whether to retrieve the bucket keys
    # @option options [true,false] :props (true) whether to retreive the bucket properties
    # @return [Bucket] the requested bucket
    def bucket(name, options={})
      options.assert_valid_keys(:keys, :props)
      response = http.get(200, name, options, {})
      Bucket.new(self, name).load(response)
    end

    private
    def make_client_id
      b64encode(rand(MAX_CLIENT_ID))
    end

    def b64encode(n)
      Base64.encode64([n].pack("N")).chomp
    end
  end
end
