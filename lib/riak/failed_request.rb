# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'riak'

module Riak
  # Exception raised when the expected response code from Riak
  # fails to match the actual response code.
  class FailedRequest < StandardError
    include Util::Translation
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
      super t("failed_request", :expected => @expected.inspect, :code => @code, :body => @body)
    end
  end
end
