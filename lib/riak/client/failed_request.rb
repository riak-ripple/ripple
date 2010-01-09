require 'riak'

module Riak
  class Client
    # Exception raised when the expected response code from Riak
    # fails to match the actual response code.
    class FailedRequest < StandardError
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
        super "Expected #{@expected} from Riak but received #{@code}."
      end
    end
  end
end