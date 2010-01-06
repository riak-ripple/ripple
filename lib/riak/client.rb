require 'riak'
require 'base64'

module Riak
  class Client
    MAX_CLIENT_ID = 4294967296 #:nodoc:

    attr_reader :host, :port, :client_id, :prefix

    def initialize(*args)
      options = args.extract_options!.symbolize_keys
      options.assert_valid_keys(:host, :port, :prefix, :client_id)
      host, port = args
      {
        :host => host || "127.0.0.1",
        :port => port || 8098,
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

    private
    def make_client_id      
      b64encode(rand(MAX_CLIENT_ID))
    end

    def b64encode(n)
      Base64.encode64([n].pack("N")).chomp
    end
  end
end
