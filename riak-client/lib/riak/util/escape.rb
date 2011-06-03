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
  end

  self.escaper = URI

  module Util
    # Methods for escaping URL segments.
    module Escape
      # CGI-escapes bucket or key names that may contain slashes for use in URLs.
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the escaped path segment
      def escape(bucket_or_key)
        Riak.escaper.escape(bucket_or_key.to_s).gsub("+", "%20").gsub('/', "%2F")
      end

      # CGI-unescapes bucket or key names
      # @param [String] bucket_or_key the bucket or key name
      # @return [String] the unescaped name
      def unescape(bucket_or_key)
        Riak.escaper.unescape(bucket_or_key.to_s)
      end
    end
  end
end
