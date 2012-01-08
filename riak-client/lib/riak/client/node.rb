module Riak
  class Client
    class Node
      # Represents a single riak node in a cluster.

      include Util::Translation
      include Util::Escape

      VALID_OPTIONS = [:host, :http_port, :pb_port, :http_paths, :prefix,
        :mapred, :luwak, :solr, :port, :basic_auth, :ssl_options, :ssl]

      # For a score which halves in 10 seconds, choose
      # ln(1/2)/10
      ERRORS_DECAY_RATE = Math.log(0.5)/10

      # What IP address or hostname does this node listen on?
      attr_accessor :host
      # Which port does the HTTP interface listen on?
      attr_accessor :http_port
      # Which port does the protocol buffers interface listen on?
      attr_accessor :pb_port
      # A hash of HTTP paths used on this node.
      attr_accessor :http_paths
      # A "user:password" string.
      attr_reader :basic_auth
      attr_accessor :ssl_options
      # A Decaying rate of errors.
      attr_reader :error_rate

      def initialize(client, opts = {})
        @client = client
        @ssl = opts[:ssl]
        @ssl_options = opts[:ssl_options]
        @host = opts[:host] || "127.0.0.1"
        @http_port = opts[:http_port] || opts[:port] || 8098
        @pb_port = opts[:pb_port] || 8087
        @http_paths = {
          :prefix => opts[:prefix] || "/riak/",
          :mapred => opts[:mapred] || "/mapred",
          :luwak =>  opts[:luwak]  || "/luwak",
          :solr =>   opts[:solr]   || "/solr" # Unused?
        }.merge(opts[:http_paths] || {})
        self.basic_auth = opts[:basic_auth]

        @error_rate = Decaying.new
      end

      def ==(o)
        o.kind_of? Node and
          @host == o.host and
          @http_port == o.http_port and
          @pb_port == o.pb_port
      end

      # Sets the HTTP Basic Authentication credentials.
      # @param [String] value an auth string in the form "user:password"
      def basic_auth=(value)
        case value
        when nil
          @basic_auth = nil
        when String
          raise ArgumentError, t("invalid_basic_auth") unless value.to_s.split(':').length === 2
          @basic_auth = value
        end
      end

      # Can this node be used for HTTP requests?
      def http?
        # TODO: Need to sort out capabilities
        true
      end

      # Can this node be used for protocol buffers requests?
      def protobuffs?
        # TODO: Need to sort out capabilities
        true
      end

      # Enables or disables SSL on this node to be utilized by the HTTP
      # Backends
      def ssl=(value)
        @ssl_options = Hash === value ? value : {}
        value ? ssl_enable : ssl_disable
      end

      # Checks if SSL is enabled for HTTP
      def ssl_enabled?
        @client.protocol == 'https' || @ssl_options.present?
      end

      def ssl_enable
        @client.protocol = 'https'
        @ssl_options[:pem] = File.read(@ssl_options[:pem_file]) if @ssl_options[:pem_file]
        @ssl_options[:verify_mode] ||= "peer" if @ssl_options.stringify_keys.any? {|k,v| %w[pem ca_file ca_path].include?(k)}
        @ssl_options[:verify_mode] ||= "none"
        raise ArgumentError.new(t('invalid_ssl_verify_mode', :invalid => @ssl_options[:verify_mode])) unless %w[none peer].include?(@ssl_options[:verify_mode])

        @ssl_options
      end

      def ssl_disable
        @client.protocol = 'http'
        @ssl_options  = nil
      end

      def inspect
        "<#Node #{@host}:#{@http_port}:#{@pb_port}>"
      end
    end
  end
end
