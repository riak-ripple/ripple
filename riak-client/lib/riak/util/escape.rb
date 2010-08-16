module Riak
  module Util
    module Escape
      # CGI-escapes bucket or key names that may contain slashes for use in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def escape(bucket_or_key)
        CGI.escape(bucket_or_key.to_s).gsub("+", "%20")
      end
    end
  end
end
