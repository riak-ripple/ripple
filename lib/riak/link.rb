require 'riak'

module Riak
  # Represents a link between various things in Riak
  Link = Struct.new("Link", :url, :rel)

  # @param [String] header_string the string value of the Link: HTTP header from a Riak response
  # @return [Array<Link>] an array of Riak::Link structs parsed from the header
  def Link.parse(header_string)
    header_string.scan(%r{<([^>]+)>\s*;\s*rel="([^"]+)"}).map do |match|
      new(match[0], match[1])
    end
  end
  
end
