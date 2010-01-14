require 'riak'

module Riak
  # Represents a link between various things in Riak
  class Link

    # @return [String] the URL (relative or absolute) of the related resource
    attr_accessor :url

    # @return [String] the relationship ("rel") of the other resource to this one
    attr_accessor :rel

    # @param [String] header_string the string value of the Link: HTTP header from a Riak response
    # @return [Array<Link>] an array of Riak::Link structs parsed from the header
    def self.parse(header_string)
      header_string.scan(%r{<([^>]+)>\s*;\s*rel="([^"]+)"}).map do |match|
        new(match[0], match[1])
      end
    end

    def initialize(url, rel)
      @url, @rel = url, rel
    end

    def to_s
      %Q[<#{@url}>; rel="#{@rel}"]
    end
  end
end
