
require 'tempfile'
require 'delegate'
require 'riak'
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/failed_request'
require 'riak/client/search'
require 'riak/client/http_backend'
require 'riak/client/net_http_backend'
require 'riak/client/excon_backend'
require 'riak/client/protobuffs_backend'
require 'riak/client/beefcake_protobuffs_backend'
require 'riak/bucket'

module Riak
  # A client connection to Riak.
  class Client
    include Util::Translation
    include Util::Escape

    # When using integer client IDs, the exclusive upper-bound of valid values.
    MAX_CLIENT_ID = 4294967296

    # Array of valid protocols
    PROTOCOLS = %w[http https pbc]

    # Regexp for validating hostnames, lifted from uri.rb in Ruby 1.8.6
    HOST_REGEX = /^(?:(?:(?:[a-zA-Z\d](?:[-a-zA-Z\d]*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:[-a-zA-Z\d]*[a-zA-Z\d])?)\.?|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\[(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|(?:(?:[a-fA-F\d]{1,4}:)*[a-fA-F\d]{1,4})?::(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))?)\])$/n

    VALID_OPTIONS = [:protocol, :host, :port, :http_port, :pb_port, :prefix, :client_id, :mapred, :luwak, :http_backend, :protobuffs_backend, :ssl, :basic_auth]

    # @return [String] The protocol to use for the Riak endpoint
    attr_reader :protocol

    # @return [String] The host or IP address for the Riak endpoint
    attr_reader :host

    # @return [Fixnum] The HTTP(S) port for the Riak endpoint
    attr_reader :http_port

    # @return [Fixnum] The Protocol Buffers port for the Riak endpoint
    attr_reader :pb_port

    # @return [String] The user:pass for http basic authentication
    attr_reader :basic_auth

    # @return [Hash|nil] The SSL options that get built when using SSL
    attr_reader :ssl_options

    # @return [String] The internal client ID used by Riak to route responses
    attr_reader :client_id

    # @attr_writer [Hash|nil] The writer that will build valid SSL options
    #     from the provided config
    attr_writer :ssl

    # @return [String] The URL path prefix to the "raw" HTTP endpoint
    attr_accessor :prefix

    # @return [String] The URL path to the map-reduce HTTP endpoint
    attr_accessor :mapred

    # @return [String] The URL path to the luwak HTTP endpoint
    attr_accessor :luwak

    # @return [String] The URL path prefix to the Solr HTTP endpoint
    attr_accessor :solr

    # @return [Symbol] The HTTP backend/client to use
    attr_accessor :http_backend

    # @return [Symbol] The Protocol Buffers backend/client to use
    attr_accessor :protobuffs_backend

    # Creates a client connection to Riak
    # @param [Hash] options configuration options for the client
    # @option options [String] :host ('127.0.0.1') The host or IP address for the Riak endpoint
    # @option options [Fixnum] :port (8098) The port of the Riak HTTP endpoint
    # @option options [String] :prefix ('/riak/') The URL path prefix to the main HTTP endpoint
    # @option options [String] :mapred ('/mapred') The path to the map-reduce HTTP endpoint
    # @option options [Fixnum, String] :client_id (rand(MAX_CLIENT_ID)) The internal client ID used by Riak to route responses
    # @option options [String, Symbol] :http_backend (:NetHTTP) which  HTTP backend to use
    # @option options [String, Symbol] :protobuffs_backend (:Beefcake) which Protocol Buffers backend to use
    # @raise [ArgumentError] raised if any invalid options are given
    def initialize(options={})
      unless (options.keys - VALID_OPTIONS).empty?
        raise ArgumentError, t("invalid_options")
      end
      self.protocol           = options[:protocol]           || "http"
      self.ssl                = options[:ssl]                if options[:ssl]
      self.host               = options[:host]               || "127.0.0.1"
      self.http_port          = options[:http_port]          || 8098
      self.pb_port            = options[:pb_port]            || 8087
      self.port               = options[:port]               if options[:port]
      self.prefix             = options[:prefix]             || "/riak/"
      self.mapred             = options[:mapred]             || "/mapred"
      self.luwak              = options[:luwak]              || "/luwak"
      self.solr               = options[:solr]               || "/solr"
      self.http_backend       = options[:http_backend]       || :NetHTTP
      self.protobuffs_backend = options[:protobuffs_backend] || :Beefcake
      self.basic_auth         = options[:basic_auth]         if options[:basic_auth]
      self.client_id          = options[:client_id]          if options[:client_id]
    end

    # Set the client ID for this client. Must be a string or Fixnum value 0 =< value < MAX_CLIENT_ID.
    # @param [String, Fixnum] value The internal client ID used by Riak to route responses
    # @raise [ArgumentError] when an invalid client ID is given
    # @return [String] the assigned client ID
    def client_id=(value)
      value = case value
              when 0...MAX_CLIENT_ID, String
                value
              else
                raise ArgumentError, t("invalid_client_id", :max_id => MAX_CLIENT_ID)
              end
      backend.set_client_id value if backend.respond_to?(:set_client_id)
      @client_id = value
    end

    def client_id
      @client_id ||= backend.respond_to?(:get_client_id) ? backend.get_client_id : make_client_id
    end

    # Set the protocol of the Riak endpoint.  Value must be in the
    # Riak::Client::PROTOCOLS array.
    # @raise [ArgumentError] if the protocol is not in PROTOCOLS
    # @return [String] the protocol being assigned
    def protocol=(value)
      unless PROTOCOLS.include?(value.to_s)
        raise ArgumentError, t("protocol_invalid", :invalid => value, :valid => PROTOCOLS.join(', '))
      end
      @ssl_options ||= {} if value == 'https'
      @ssl_options = nil if value == 'http'
      @backend = nil
      @protocol = value
    end

    # Set the hostname of the Riak endpoint. Must be an IPv4, IPv6, or valid hostname
    # @param [String] value The host or IP address for the Riak endpoint
    # @raise [ArgumentError] if an invalid hostname is given
    # @return [String] the assigned hostname
    def host=(value)
      raise ArgumentError, t("hostname_invalid") unless String === value && value.present? && value =~ HOST_REGEX
      @host = value
    end

    # @return [Fixnum] The port of the Riak endpoint
    # @deprecated Ports for HTTP(S) and Protocol Buffers are
    #    segregated. Use {#http_port} or {#pb_port}.
    def port
      warn(t('deprecated.port', :backtrace => caller.join("\n")))
      case protocol
      when /http/i
        http_port
      when /pbc/i
        pb_port
      end
    end

    # Set the port number of the Riak endpoint. This must be an
    # integer between 0 and 65535.
    # @deprecated Ports for HTTP(S) and Protocol Buffers are
    #    segregated. Use {#http_port=} or {#pb_port=}.
    # @param [Fixnum] value The port number of the Riak endpoint
    # @raise [ArgumentError] if an invalid port number is given
    # @return [Fixnum] the assigned port number
    def port=(value)
      warn(t('deprecated.port', :backtrace => caller[0..2].join("\n    ")))
      raise ArgumentError, t("port_invalid") unless (0..65535).include?(value)
      case protocol
      when /http/i
        self.http_port = value
      when /pbc/i
        self.pb_port = value
      end
    end

    # Set the HTTP(S) port for the Riak endpoint
    # @param [Fixnum] value The HTTP port number of the Riak endpoint
    # @raise [ArgumentError] if an invalid port number is given
    # @return [Fixnum] the assigned port number
    def http_port=(value)
      raise ArgumentError, t("port_invalid") unless (0..65535).include?(value)
      @http_port = value
    end

    # Set the Protocol Buffers port for the Riak endpoint
    # @param [Fixnum] value The Protocol Buffers port number of the Riak endpoint
    # @raise [ArgumentError] if an invalid port number is given
    # @return [Fixnum] the assigned port number
    def pb_port=(value)
      raise ArgumentError, t("port_invalid") unless (0..65535).include?(value)
      @pb_port = value
    end


    # Sets the HTTP Basic Authentication credentials.
    # @param [String] value an auth string in the form "user:password"
    def basic_auth=(value)
      raise ArgumentError, t("invalid_basic_auth") unless value.to_s.split(':').length === 2
      @basic_auth = value
    end

    # Sets the desired HTTP backend
    def http_backend=(value)
      @http, @backend = nil, nil
      @http_backend = value
    end

    # Sets the desired Protocol Buffers backend
    def protobuffs_backend=(value)
      @protobuffs, @backend = nil, nil
      @protobuffs_backend = value
    end

    # Enables or disables SSL on the client to be utilized by the HTTP Backends
    def ssl=(value)
      @ssl_options = Hash === value ? value : {}
      value ? ssl_enable : ssl_disable
    end

    # Checks if SSL is enabled for HTTP
    def ssl_enabled?
      protocol == 'https' || @ssl_options.present?
    end

    # Automatically detects and returns an appropriate HTTP backend.
    # The HTTP backend is used internally by the Riak client, but can also
    # be used to access the server directly.
    # @return [HTTPBackend] the HTTP backend for this client
    def http
      @http ||= begin
                  klass = self.class.const_get("#{@http_backend}Backend")
                  if klass.configured?
                    klass.new(self)
                  else
                    raise t('http_configuration', :backend => @http_backend)
                  end
                end
    end

    # Automatically detects and returns an appropriate Protocol
    # Buffers backend.  The Protocol Buffers backend is used
    # internally by the Riak client but can also be used to access the
    # server directly.
    # @return [ProtobuffsBackend] the Protocol Buffers backend for
    #    this client
    def protobuffs
      @protobuffs ||= begin
                        klass = self.class.const_get("#{@protobuffs_backend}ProtobuffsBackend")
                        if klass.configured?
                          klass.new(self)
                        else
                          raise t('protobuffs_configuration', :backend => @protobuffs_backend)
                        end
                      end
    end

    # Returns a backend for operations that are protocol-independent.
    # You can change which type of backend is used by setting the
    # {#protocol}.
    # @return [HTTPBackend,ProtobuffsBackend] an appropriate client backend
    def backend
      @backend ||= case @protocol.to_s
                   when /https?/i
                     http
                   when /pbc/i
                     protobuffs
                   end
    end

    # Pings the Riak server to check for liveness.
    # @return [true,false] whether the Riak server is alive and reachable
    def ping
      backend.ping
    end

    # Retrieves a bucket from Riak.
    # @param [String] bucket the bucket to retrieve
    # @param [Hash] options options for retrieving the bucket
    # @option options [Boolean] :keys (false whether to retrieve the bucket keys
    # @option options [Boolean] :props (false) whether to retreive the bucket properties
    # @return [Bucket] the requested bucket
    def bucket(name, options={})
      unless (options.keys - [:keys, :props]).empty?
        raise ArgumentError, "invalid options"
      end
      @bucket_cache ||= {}
      (@bucket_cache[name] ||= Bucket.new(self, name)).tap do |b|
        b.props if options[:props]
        b.keys  if options[:keys]
      end
    end
    alias :[] :bucket

    # Lists buckets which have keys stored in them.
    # @note This is an expensive operation and should be used only
    #       in development.
    # @return [Array<Bucket>] a list of buckets
    def buckets
      backend.list_buckets.map {|name| Bucket.new(self, name) }
    end
    alias :list_buckets :buckets

    # Stores a large file/IO-like object in Riak via the "Luwak" interface.
    # @overload store_file(filename, content_type, data)
    #   Stores the file at the given key/filename
    #   @param [String] filename the key/filename for the object
    #   @param [String] content_type the MIME Content-Type for the data
    #   @param [IO, String] data the contents of the file
    # @overload store_file(content_type, data)
    #   Stores the file with a server-determined key/filename
    #   @param [String] content_type the MIME Content-Type for the data
    #   @param [IO-like, String] data the contents of the file
    # @return [String] the key/filename where the object was stored
    def store_file(*args)
      data, content_type, filename = args.reverse
      if filename
        http.put(204, luwak, escape(filename), data, {"Content-Type" => content_type})
        filename
      else
        response = http.post(201, luwak, data, {"Content-Type" => content_type})
        response[:headers]["location"].first.split("/").last
      end
    end

    # Retrieves a large file/IO object from Riak via the "Luwak"
    # interface. Streams the data to a temporary file unless a block
    # is given.
    # @param [String] filename the key/filename for the object
    # @return [IO, nil] the file (also having content_type and
    #   original_filename accessors). The file will need to be
    #   reopened to be read. nil will be returned if a block is given.
    # @yield [chunk] stream contents of the file through the
    #     block. Passing the block will result in nil being returned
    #     from the method.
    # @yieldparam [String] chunk a single chunk of the object's data
    def get_file(filename, &block)
      if block_given?
        http.get(200, luwak, escape(filename), &block)
        nil
      else
        tmpfile = LuwakFile.new(escape(filename))
        begin
          response = http.get(200, luwak, escape(filename)) do |chunk|
            tmpfile.write chunk
          end
          tmpfile.content_type = response[:headers]['content-type'].first
          tmpfile
        ensure
          tmpfile.close
        end
      end
    end

    # Deletes a file stored via the "Luwak" interface
    # @param [String] filename the key/filename to delete
    def delete_file(filename)
      http.delete([204,404], luwak, escape(filename))
      true
    end

    # Checks whether a file exists in "Luwak".
    # @param [String] key the key to check
    # @return [true, false] whether the key exists in "Luwak"
    def file_exists?(key)
      result = http.head([200,404], luwak, escape(key))
      result[:code] == 200
    end
    alias :file_exist? :file_exists?

    # @return [String] A representation suitable for IRB and debugging output.
    def inspect
      "#<Riak::Client #{protocol}://#{host}:#{protocol == 'pbc' ? pb_port : http_port}>"
    end

    private
    def make_client_id
      rand(MAX_CLIENT_ID)
    end

    def ssl_enable
      self.protocol = 'https'
      @ssl_options[:pem] = File.read(@ssl_options[:pem_file]) if @ssl_options[:pem_file]
      @ssl_options[:verify_mode] ||= "peer" if @ssl_options.stringify_keys.any? {|k,v| %w[pem ca_file ca_path].include?(k)}
      @ssl_options[:verify_mode] ||= "none"
      raise ArgumentError.new(t('invalid_ssl_verify_mode', :invalid => @ssl_options[:verify_mode])) unless %w[none peer].include?(@ssl_options[:verify_mode])

      @ssl_options
    end

    def ssl_disable
      self.protocol = 'http'
      @ssl_options  = nil
    end

    # @private
    class LuwakFile < DelegateClass(Tempfile)
      attr_accessor :original_filename, :content_type
      alias :key :original_filename
      def initialize(fn)
        super(Tempfile.new(fn))
        @original_filename = fn
      end
    end
  end
end
