
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/walk_spec'

module Riak
  # Represents a link from one object to another in Riak
  class Link
    include Util::Translation
    include Util::Escape

    # @return [String] the relationship tag (or "rel") of the other resource to this one
    attr_accessor :tag
    alias_method :rel, :tag
    alias_method :rel=, :tag=

    # @return [String] the bucket of the related resource
    attr_accessor :bucket

    # @return [String] the key of the related resource
    attr_accessor :key

    %w{bucket key}.each do |m|
      define_method("#{m}=") { |value|
        @url = nil
        instance_variable_set("@#{m}", value)
      }
    end

    # @param [String] header_string the string value of the Link: HTTP header from a Riak response
    # @return [Array<Link>] an array of Riak::Link structs parsed from the header
    def self.parse(header_string)
      header_string.scan(%r{<([^>]+)>\s*;\s*(?:rel|riaktag)=\"([^\"]+)\"}).map do |match|
        new(match[0], match[1])
      end
    end

    # @overload initialize(url, tag)
    #   @param [String] url the url of the related resource
    #   @param [String] tag the tag for the related resource
    # @overload initialize(bucket, key, tag)
    #   @param [String] bucket the bucket of the related resource
    #   @param [String] key the key of the related resource
    #   @param [String] tag the tag for the related resource
    def initialize(*args)
      raise ArgumentError unless (2..3).include?(args.size)
      if args.size == 2
        self.url, @tag = args
      else
        @bucket, @key, @tag = args
      end
    end

    # @return [String] the URL (relative or absolute) of the related resource
    def url
      @url ||= "/riak/#{escape(bucket)}" + (key.blank? ? "" : "/#{escape(key)}")
    end

    def url=(value)
      @url = value
      @bucket = unescape($1) if value =~ %r{^/[^/]+/([^/]+)/?}
      @key = unescape($1) if value =~ %r{^/[^/]+/[^/]+/([^/]+)/?}
    end

    def inspect; to_s; end

    def to_s
      %Q[<#{url}>; riaktag="#{tag}"]
    end

    def hash
      self.to_s.hash
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a?(Link) && url == other.url && tag == other.tag
    end

    def to_walk_spec
      raise t("bucket_link_conversion") if tag == "up" || key.nil?
      WalkSpec.new(:bucket => bucket, :tag => tag)
    end
  end
end
