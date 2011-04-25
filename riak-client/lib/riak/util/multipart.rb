require 'riak/util/headers'

module Riak
  module Util
    # Utility methods for handling multipart/mixed responses
    module Multipart
      extend self
      # Parses a multipart/mixed body into its constituent parts, including nested multipart/mixed sections
      # @param [String] data the multipart body data
      # @param [String] boundary the boundary string given in the Content-Type header
      def parse(data, boundary)
        contents = data.match(end_boundary_regex(boundary)).pre_match rescue ""
        contents.split(inner_boundary_regex(boundary)).reject(&:blank?).map do |part|
          parse_multipart_section(part)
        end.compact
      end

      # Extracts the boundary string from a Content-Type header that is a multipart type
      # @param [String] header_string the Content-Type header
      # @return [String] the boundary string separating each part
      def extract_boundary(header_string)
        $1 if header_string =~ /boundary=([A-Za-z0-9\'()+_,-.\/:=?]+)/
      end

      private
      def end_boundary_regex(boundary)
        /\r?\n--#{Regexp.escape(boundary)}--\r?\n/
      end

      def inner_boundary_regex(boundary)
        /\r?\n--#{Regexp.escape(boundary)}\r?\n/
      end

      def parse_multipart_section(part)
        headers = Headers.new
        if md = part.match(/\r?\n\r?\n/)
          body = md.post_match
          md.pre_match.split(/\r?\n/).each do |line|
            headers.parse(line)
          end

          if headers["content-type"] =~ /multipart\/mixed/
            boundary = extract_boundary(headers.to_hash["content-type"].first)
            parse(body, boundary)
          else
            {:headers => headers.to_hash, :body => body}
          end
        end
      end
    end
  end
end
