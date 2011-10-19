
require 'riak/util/translation'
require 'riak/json'

module Riak
  # Exception raised when receiving an unexpected client response from
  # Riak.
  class FailedRequest < StandardError
    include Util::Translation

    def initialize(message)
      super(message ||  t('failed_request'))
    end
  end

  # Exception raised when the expected HTTP response code from Riak
  # fails to match the actual response code.
  class HTTPFailedRequest < FailedRequest
    # @return [Symbol] the HTTP method, one of :head, :get, :post, :put, :delete
    attr_reader :method
    # @return [Fixnum] the expected response code
    attr_reader :expected
    # @return [Fixnum] the received response code
    attr_reader :code
    # @return [Hash] the response headers
    attr_reader :headers
    # @return [String] the response body, if present
    attr_reader :body

    def initialize(method, expected_code, received_code, headers, body)
      @method, @expected, @code, @headers, @body = method, expected_code, received_code, headers, body
      super t("http_failed_request", :expected => @expected.inspect, :code => @code, :body => @body)
    end

    def is_json?
      headers['content-type'].include?('application/json')
    end

    # @return [true,false] whether the error represents a "not found" response
    def not_found?
      @code.to_i == 404
    end

    # @return [true,false] whether the error represents an internal
    #   server error
    def server_error?
      @code.to_i == 500
    end
  end

  # Exception raised when receiving an unexpected Protocol Buffers response from Riak
  class ProtobuffsFailedRequest < FailedRequest
    def initialize(code, message)
      super t('protobuffs_failed_request', :code => code, :body => message)
      @original_message = message
      @not_found = code == :not_found
      @server_error = code == :server_error
    end

    # @return [true, false] whether the error response is in JSON
    def is_json?
      begin
        JSON.parse(original_message)
        true
      rescue
        false
      end
    end

    # @return [true,false] whether the error represents a "not found" response
    def not_found?
      @not_found
    end

    # @return [true,false] whether the error represents an internal
    #   server error
    def server_error?
      @server_error
    end
  end
end
