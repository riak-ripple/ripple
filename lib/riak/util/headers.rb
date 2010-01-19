module Riak
  module Util
    # Represents headers from an HTTP response
    class Headers
      include Net::HTTPHeader

      def initialize
        initialize_http_header({})
      end
      
      # Parse a single header line into its key and value
      # @param [String] chunk a single header line
      def self.parse(chunk)
        line = chunk.strip
        # thanks Net::HTTPResponse
        return [nil,nil] if chunk =~ /\AHTTP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/in
        m = /\A([^:]+):\s*/.match(line)
        [m[1], m.post_match] rescue [nil, nil]
      end
      
      # Parses a header line and adds it to the header collection
      # @param [String] chunk a single header line
      def parse(chunk)
        key, value = self.class.parse(chunk)
        add_field(key, value) if key && value
      end
    end
  end
end
