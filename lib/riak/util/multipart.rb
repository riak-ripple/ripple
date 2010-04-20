# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'riak'

module Riak
  module Util
    # Utility methods for handling multipart/mixed responses
    module Multipart
      extend self
      # Parses a multipart/mixed body into its constituent parts, including nested multipart/mixed sections
      # @param [String] data the multipart body data
      # @param [String] boundary the boundary string given in the Content-Type header
      def parse(data, boundary)
        contents = data.match(/\r?\n--#{Regexp.escape(boundary)}--\r?\n/).pre_match rescue ""
        contents.split(/\r?\n--#{Regexp.escape(boundary)}\r?\n/).reject(&:blank?).map do |part|
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
        end.compact
      end

      # Extracts the boundary string from a Content-Type header that is a multipart type
      # @param [String] header_string the Content-Type header
      # @return [String] the boundary string separating each part
      def extract_boundary(header_string)
        $1 if header_string =~ /boundary=([A-Za-z0-9\'()+_,-.\/:=?]+)/
      end
    end
  end
end
