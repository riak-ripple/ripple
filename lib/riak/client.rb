require 'riak'

module Riak
  class Client
    class FailedRequest < StandardError
      attr_reader :method, :expected, :code, :headers, :body
      
      def initialize(method, expected_code, received_code, headers, body)
        @method, @expected, @code, @headers, @body = method, expected_code, received_code, headers, body
        super "Expected #{@expected} from Riak but received #{@code}."
      end
    end
    
    autoload :HTTPBackend, "riak/client/http_backend"
    autoload :NetHTTPBackend, "riak/client/net_http_backend"
    autoload :CurbBackend, "riak/client/curb_backend"
    
    MAX_CLIENT_ID = 4294967296 #:nodoc:
    
    attr_reader :host, :port, :client_id
    attr_accessor :prefix

    def initialize(options={})
      options.assert_valid_keys(:host, :port, :prefix, :client_id)
      {
        :host => "127.0.0.1",
        :port => 8098,
        :client_id => make_client_id,
        :prefix => "/raw/"
      }.merge(options).each do |k,v|
        if respond_to?("#{k}=")
          send("#{k}=", v)
        else
          instance_variable_set("@#{k}", v)
        end
      end
      raise ArgumentError, "You must specify a host and port, or use the defaults of 127.0.0.1:8098" unless @host && @port
    end

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
    
    def host=(value)
      raise ArgumentError, "host must be a valid hostname" unless String === value && value.present? && value =~ URI::REGEXP::HOST
      @host = value
    end

    def port=(value)
      raise ArgumentError, "port must be an integer between 1 and 65535" unless (1..65535).include?(value)
      @port = value
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
