require 'cgi'

module Riak
  module Util
    # Methods for escaping URL segments.
    module Escape
      # CGI-escapes bucket or key names that may contain slashes for use in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def escape(bucket_or_key)
        CGI.escape(bucket_or_key.to_s).gsub("+", "%20")
      end

      # CGI-unescapes bucket or key names
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the unescaped name
      def unescape(bucket_or_key)
        CGI.unescape(bucket_or_key.to_s)
      end
    end
  end
end
