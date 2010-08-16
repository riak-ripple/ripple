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
  # Represents a link from one object to another in Riak
  class Link
    include Util::Translation
    # @return [String] the URL (relative or absolute) of the related resource
    attr_accessor :url

    # @return [String] the relationship ("rel") of the other resource to this one
    attr_accessor :rel
    alias :tag :rel
    alias :tag= :rel=

    # @param [String] header_string the string value of the Link: HTTP header from a Riak response
    # @return [Array<Link>] an array of Riak::Link structs parsed from the header
    def self.parse(header_string)
      header_string.scan(%r{<([^>]+)>\s*;\s*(?:rel|riaktag)=\"([^\"]+)\"}).map do |match|
        new(match[0], match[1])
      end
    end

    def initialize(url, rel)
      @url, @rel = url, rel
    end

    # @return [String] bucket_name, if the Link url is a known Riak link ("/riak/<bucket>/<key>")
    def bucket
      CGI.unescape($1) if url =~ %r{^/[^/]+/([^/]+)/?}
    end
    
    # @return [String] key, if the Link url is a known Riak link ("/riak/<bucket>/<key>")
    def key
      CGI.unescape($1) if url =~ %r{^/[^/]+/[^/]+/([^/]+)/?}
    end

    def inspect; to_s; end

    def to_s
      %Q[<#{@url}>; riaktag="#{@rel}"]
    end

    def hash
      self.to_s.hash
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a?(Link) && url == other.url && rel == other.rel
    end

    def to_walk_spec
      raise t("bucket_link_conversion") if @rel == "up" || key.nil?
      WalkSpec.new(:bucket => bucket, :tag => @rel)
    end
  end
end
