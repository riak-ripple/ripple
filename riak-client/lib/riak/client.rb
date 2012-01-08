require 'tempfile'
require 'delegate'
require 'riak'
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/failed_request'
require 'riak/client/pool'
require 'riak/client/decaying'
require 'riak/client/node'
require 'riak/client/search'
require 'riak/client/http_backend'
require 'riak/client/net_http_backend'
require 'riak/client/excon_backend'
require 'riak/client/protobuffs_backend'
require 'riak/client/beefcake_protobuffs_backend'
require 'riak/bucket'
require 'riak/stamp'

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

    # Valid constructor options.
    VALID_OPTIONS = [:protocol, :nodes, :client_id, :http_backend, :protobuffs_backend] | Node::VALID_OPTIONS

    # Network errors.
    NETWORK_ERRORS = [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::ENETDOWN,
      Errno::ENETRESET,
      Errno::ENETUNREACH,
      SocketError,
      SystemCallError,
    ]

    # @return [String] The protocol to use for the Riak endpoint
    attr_reader :protocol

    # @return [Array] The set of Nodes this client can communicate with.
    attr_accessor :nodes

    # @return [String] The internal client ID used by Riak to route responses
    attr_reader :client_id

    # @return [Symbol] The HTTP backend/client to use
    attr_accessor :http_backend

    # @return [Client::Pool] A pool of HTTP connections
    attr_reader :http_pool

    # @return [Symbol] The Protocol Buffers backend/client to use
    attr_accessor :protobuffs_backend

    # @return [Client::Pool] A pool of protobuffs connections
    attr_reader :protobuffs_pool

    # Creates a client connection to Riak
    # @param [Hash] options configuration options for the client
    # @option options [Array] :nodes A list of nodes this client connects to.
    #   Each element of the list is a hash which is passed to Node.new, e.g.
    #   {host: '127.0.0.1', pb_port: 1234, ...}.
    #   If no nodes are given, a single node is constructed from the remaining
    #   options given to Client.new.
    # @option options [String] :host ('127.0.0.1') The host or IP address for the Riak endpoint
    # @option options [Fixnum] :http_port (8098) The port of the Riak HTTP endpoint
    # @option options [Fixnum] :pb_port (8087) The port of the Riak Protocol Buffers endpoint
    # @option options [String] :prefix ('/riak/') The URL path prefix to the main HTTP endpoint
    # @option options [String] :mapred ('/mapred') The path to the map-reduce HTTP endpoint
    # @option options [Fixnum, String] :client_id (rand(MAX_CLIENT_ID)) The internal client ID used by Riak to route responses
    # @option options [String, Symbol] :http_backend (:NetHTTP) which  HTTP backend to use
    # @option options [String, Symbol] :protobuffs_backend (:Beefcake) which Protocol Buffers backend to use
    # @raise [ArgumentError] raised if any invalid options are given
    def initialize(options={})
      if options.include? :port
        warn(t('deprecated.port', :backtrace => caller[0..2].join("\n    ")))
      end

      unless (evil = options.keys - VALID_OPTIONS).empty?
        raise ArgumentError, "#{evil.inspect} are not valid options for Client.new"
      end

      @nodes = (options[:nodes] || []).map do |n|
        Client::Node.new self, n
      end
      if @nodes.empty? or options[:host] or options[:http_port] or options[:pb_port]
        @nodes |= [Client::Node.new(self, options)]
      end

      @protobuffs_pool = Pool.new(
                                  method(:new_protobuffs_backend),
                                  lambda { |b| b.teardown }
                                  )

      @http_pool = Pool.new(
                            method(:new_http_backend),
                            lambda { |b| b.teardown }
                            )

      self.protocol           = options[:protocol]           || "http"
      self.http_backend       = options[:http_backend]       || :NetHTTP
      self.protobuffs_backend = options[:protobuffs_backend] || :Beefcake
      self.client_id          = options[:client_id]          if options[:client_id]
    end

    # Yields a backend for operations that are protocol-independent.
    # You can change which type of backend is used by setting the
    # {#protocol}.
    # @yield [HTTPBackend,ProtobuffsBackend] an appropriate client backend
    def backend(&block)
      case @protocol.to_s
      when /https?/i
        http &block
      when /pbc/i
        protobuffs &block
      end
    end

    # Sets basic HTTP auth on all nodes.
    def basic_auth=(auth)
      @nodes.each do |node|
        node.basic_auth = auth
      end
      auth
    end

    # Retrieves a bucket from Riak.
    # @param [String] bucket the bucket to retrieve
    # @param [Hash] options options for retrieving the bucket
    # @option options [Boolean] :props (false) whether to retreive the bucket properties
    # @return [Bucket] the requested bucket
    def bucket(name, options={})
      unless (options.keys - [:props]).empty?
        raise ArgumentError, "invalid options"
      end
      @bucket_cache ||= {}
      (@bucket_cache[name] ||= Bucket.new(self, name)).tap do |b|
        b.props if options[:props]
      end
    end
    alias :[] :bucket

    # Lists buckets which have keys stored in them.
    # @note This is an expensive operation and should be used only
    #       in development.
    # @return [Array<Bucket>] a list of buckets
    def buckets
      warn(t('list_buckets', :backtrace => caller.join("\n    "))) unless Riak.disable_list_keys_warnings
      backend do |b|
        b.list_buckets.map {|name| Bucket.new(self, name) }
      end
    end
    alias :list_buckets :buckets

    # Choose a node from a set.
    def choose_node(nodes = self.nodes)
      # Prefer nodes which have gone a reasonable time without errors.
      s = nodes.select do |node|
        node.error_rate.value < 0.1
      end

      if s.empty?
        # Fall back to minimally broken node.
        nodes.min_by do |node|
          node.error_rate.value
        end
      else
        s[rand(s.size)]
      end
    end

    # Set the client ID for this client. Must be a string or Fixnum value 0 =<
    # value < MAX_CLIENT_ID.
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

      # Change all existing backend client IDs.
      @protobuffs_pool.each do |pb|
        pb.set_client_id value if pb.respond_to?(:set_client_id)
      end
      @client_id = value
    end

    def client_id
      @client_id ||= backend do |b|
        if b.respond_to?(:get_client_id)
          b.get_client_id
        else
          make_client_id
        end
      end
    end

    # Deletes a file stored via the "Luwak" interface
    # @param [String] filename the key/filename to delete
    def delete_file(filename)
      http do |h|
        h.delete_file(filename)
      end
      true
    end

    # Delete an object. See Bucket#delete
    def delete_object(bucket, key, options = {})
      backend do |b|
        b.delete_object(bucket, key, options)
      end
    end

    # Checks whether a file exists in "Luwak".
    # @param [String] key the key to check
    # @return [true, false] whether the key exists in "Luwak"
    def file_exists?(key)
      http do |h|
        h.file_exists?(key)
      end
    end
    alias :file_exist? :file_exists?

    # Bucket properties. See Bucket#props
    def get_bucket_props(bucket)
      backend do |b|
        b.get_bucket_props bucket
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
      http do |h|
        h.get_file(filename, &block)
      end
    end

    # Queries a secondary index on a bucket. See Bucket#get_index
    def get_index(bucket, index, query)
      backend do |b|
        b.get_index bucket, index, query
      end
    end

    # Get an object. See Bucket#get
    def get_object(bucket, key, options = {})
      backend do |b|
        b.fetch_object(bucket, key, options)
      end
    end

    # Yields an HTTPBackend.
    def http(&block)
      recover_from @http_pool, &block
    end

    # Sets the desired HTTP backend
    def http_backend=(value)
      @http_backend = value
      # Shut down existing connections using the old backend
      @http_pool.clear
      @http_backend
    end

    # @return [String] A representation suitable for IRB and debugging output.
    def inspect
      "#<Riak::Client #{nodes.inspect}>"
    end

    # Link-walk.
    def link_walk(object, specs)
      http do |h|
        h.link_walk object, specs
      end
    end

    # Retrieves a list of keys in the given bucket. See Bucket#keys
    def list_keys(bucket, &block)
      if block_given?
        backend do |b|
          b.list_keys bucket, &block
        end
      else
        backend do |b|
          b.list_keys bucket
        end
      end
    end

    # Executes a mapreduce request. See MapReduce#run
    def mapred(mr, &block)
      backend do |b|
        b.mapred(mr, &block)
      end
    end

    # Creates a new HTTP backend.
    # @return [HTTPBackend] An HTTP backend for a given node.
    def new_http_backend
      klass = self.class.const_get("#{@http_backend}Backend")
      if klass.configured?
        node = choose_node(
          @nodes.select do |n|
            n.http?
          end
        )

        klass.new(self, node)
      else
        raise t('http_configuration', :backend => @http_backend)
      end
    end

    # Creates a new protocol buffers backend.
    # @return [ProtobuffsBackend] the Protocol Buffers backend for
    #    a given node.
    def new_protobuffs_backend
      klass = self.class.const_get("#{@protobuffs_backend}ProtobuffsBackend")
      if klass.configured?
        node = choose_node(
          @nodes.select do |n|
            n.protobuffs?
          end
        )

        klass.new(self, node)
      else
        raise t('protobuffs_configuration', :backend => @protobuffs_backend)
      end
    end

    # @return [Node] An arbitrary Node.
    def node
      nodes[rand nodes.size]
    end

    # Pings the Riak cluster to check for liveness.
    # @return [true,false] whether the Riak cluster is alive and reachable
    def ping
      backend do |b|
        b.ping
      end
    end

    # Yields a protocol buffers backend.
    def protobuffs(&block)
      recover_from @protobuffs_pool, &block
    end

    # Sets the desired Protocol Buffers backend
    def protobuffs_backend=(value)
      # Shutdown any connections using the old backend
      @protobuffs_backend = value
      @protobuffs_pool.clear
      @protobuffs_backend
    end

    # Set the protocol of the Riak endpoint.  Value must be in the
    # Riak::Client::PROTOCOLS array.
    # @raise [ArgumentError] if the protocol is not in PROTOCOLS
    # @return [String] the protocol being assigned
    def protocol=(value)
      unless PROTOCOLS.include?(value.to_s)
        raise ArgumentError, t("protocol_invalid", :invalid => value, :valid => PROTOCOLS.join(', '))
      end

      case value
      when 'https'
        nodes.each do |node|
          node.ssl_options ||= {}
        end
      when 'http'
        nodes.each do |node|
          node.ssl_options = nil
        end
      end

      #TODO
      @backend = nil
      @protocol = value
    end

    # Takes a pool. Acquires a backend from the pool and yields it with
    # node-specific error recovery.
    def recover_from(pool)
      skip_nodes = []
      take_opts = {}
      tries = 3

      begin
        # Only select nodes which we haven't used before.
        unless skip_nodes.empty?
          take_opts[:filter] = lambda do |backend|
            not skip_nodes.include? backend.node
          end
        end

        # Acquire a backend
        pool.take(take_opts) do |backend|
          begin
            yield backend
          rescue *NETWORK_ERRORS => e
            # Network error.
            tries -= 1

            # Notify the node that a request against it failed.
            backend.node.error_rate << 1

            # Skip this node next time.
            skip_nodes << backend.node

            # And delete this connection.
            raise Pool::BadResource, e
          end
        end
      rescue Pool::BadResource => e
        retry if tries > 0
        raise e.message
      end
    end

    # Reloads the object from Riak.
    def reload_object(object, options = {})
      backend do |b|
        b.reload_object(object, options)
      end
    end

    # Sets the properties on a bucket. See Bucket#props=
    def set_bucket_props(bucket, properties)
      # A bug in Beefcake is still giving us trouble with default booleans.
      # Until it is resolved, we'll use the HTTP backend.
      http do |b|
        b.set_bucket_props(bucket, properties)
      end
    end

    # Enables or disables SSL on all nodes, for HTTP backends.
    def ssl=(value)
      @nodes.each do |node|
        node.ssl = value
      end

      if value
        @protocol = 'https'
      else
        @protocol = 'http'
      end
      value
    end

    # Exposes a {Stamp} object for use in generating unique
    # identifiers.
    # @return [Stamp] an ID generator
    # @see Stamp#next
    def stamp
      @stamp ||= Riak::Stamp.new(self)
    end

    # Stores a large file/IO-like object in Riak via the "Luwak" interface.
    # @overload store_file(filename, content_type, data)
    #   Stores the file at the given key/filename
    #   @param [String] filename the key/filename for the object
    #   @param [String] content_type the MIME Content-Type for the data
    #   @param [IO, String] data the contents of the file
    # @overload store_file(content_type, data)
    #   Stores the file with a server-determined key/filename
    #   @param [String] content_type the MIME Content-Type for the data
    #   @param [String, #read] data the contents of the file
    # @return [String] the key/filename where the object was stored
    def store_file(*args)
      http do |h|
        h.store_file(*args)
      end
    end

    # Stores an object in Riak.
    def store_object(object, options = {})
      params = {:returnbody => true}.merge(options)
      backend do |b|
        b.store_object(object, params)
      end
    end

    private
    def make_client_id
      rand(MAX_CLIENT_ID)
    end

    def ssl_enable
      @nodes.each do |n|
        n.ssl_enable
      end
    end

    def ssl_disable
      @nodes.each do |n|
        n.ssl_disable
      end
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
