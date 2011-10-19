require 'net/http'

# Splits headers into < 8KB chunks
# @private
module Net::HTTPHeader
  def each_capitalized
    # 1.9 check
    respond_to?(:enum_for) and (block_given? or return enum_for(__method__))
    @header.each do |k,v|
      base_length = "#{k}: \r\n".length
      values = v.map {|i| i.to_s.split(", ") }.flatten
      while !values.empty?
        current_line = ""
        while values.first && current_line.length + base_length + values.first.length + 2 < 8192
          val = values.shift.strip
          current_line += current_line.empty? ? val : ", #{val}"
        end
        yield capitalize(k), current_line
      end
    end
  end
end

module Riak
  module Util
    # Represents headers from an HTTP request or response.
    # Used internally by HTTP backends for processing headers.
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
