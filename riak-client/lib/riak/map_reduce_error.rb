require 'riak/util/translation'

module Riak
  # Raised when an error occurred in the Javascript map-reduce chain.
  # The message will be the body of the JSON error response.
  class MapReduceError < StandardError; end
end
