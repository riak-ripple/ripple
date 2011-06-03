require 'multi_json'
MultiJson.engine # Force loading of an engine
require 'riak/core_ext/json'

module Riak
  class << self
    # Options that will be passed to the JSON parser and encoder.
    # Defaults to {:max_nesting => 20}
    attr_accessor :json_options
  end
  self.json_options = {:max_nesting => 20}

  # JSON module for internal use inside riak-client
  module JSON
    class << self
      # Parse a JSON string
      def parse(str)
        MultiJson.decode(str, Riak.json_options)
      end

      # Generate a JSON string
      def encode(obj)
        MultiJson.encode(obj)
      end
      alias :dump :encode
    end
  end
end
