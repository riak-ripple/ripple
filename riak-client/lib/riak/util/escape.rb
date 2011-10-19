require 'cgi'
require 'uri'

module Riak
  class << self
    # @see #escaper=
    attr_reader :escaper

    # Sets the class used for escaping URLs (buckets and keys) sent to
    # Riak. Currently only supports URI and CGI, and defaults to URI.
    # @param [Symbol,String,Class] esc A representation of which
    #   escaping class to use, either the Class itself or a String or
    #   Symbol name
    # @see Riak::Util::Escape
    def escaper=(esc)
      case esc
      when Symbol, String
        @escaper = ::Object.const_get(esc.to_s.upcase.intern) if esc.to_s =~ /uri|cgi/i
      when Class, Module
        @escaper = esc
      end
    end

    # In Riak 1.0+, buckets and keys are decoded internally before
    # being stored. This increases compatibility with the Protocol
    # Buffers transport and reduces inconsistency of link-walking
    # vs. regular operations. If the node you are connecting to has
    # set {http_url_encoding, on}, set this to true. Default is false.
    # @return [true,false] Whether Riak decodes URL-encoded paths and headers
    attr_accessor :url_decoding
  end

  self.escaper = URI
  self.url_decoding = false

  module Util
    # Methods for escaping URL segments.
    module Escape
      # Conditionally escapes buckets and keys depending on whether
      # Riak is configured to decode them. This is used in situations
      # where the bucket or key is not part of a URL, but would need
      # to be escaped on Riak 0.14 and earlier so that the name
      # matches.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def maybe_escape(bucket_or_key)
        Riak.url_decoding ? bucket_or_key : escape(bucket_or_key)
      end

      # Escapes bucket or key names that may contain slashes for use in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def escape(bucket_or_key)
        Riak.escaper.escape(bucket_or_key.to_s).gsub("+", "%20").gsub('/', "%2F")
      end

      # Conditionally unescapes buckets and keys depending on whether
      # Riak is configured to decode them. This is used in situations
      # where the bucket or key is not part of a URL, but would need
      # to be escaped on Riak 0.14 and earlier so that the name
      # matches.
      # @param [String] bucket_or_key the escaped bucket or key name
      # @return [String] the unescaped path segment
      def maybe_unescape(bucket_or_key)
        Riak.url_decoding ? bucket_or_key : unescape(bucket_or_key)
      end

      # Unescapes bucket or key names in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the unescaped name
      def unescape(bucket_or_key)
        Riak.escaper.unescape(bucket_or_key.to_s)
      end
    end
  end
end
