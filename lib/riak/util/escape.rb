module Riak
  module Util
    module Escape
      # URI-escapes bucket or key names that may contain slashes for use in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def escape(bucket_or_key)
        URI.escape(bucket_or_key).gsub("/", "%2F")
      end
    end
  end
end
