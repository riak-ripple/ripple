require 'riak'

module Riak
  # Parent class of all object types supported by ripple. {Riak::RObject} represents
  # the data stored in a bucket/key pair in the Riak database.
  class RObject
    # The order in which child classes will attempt instantiation when loading a response.
    SUBCLASS_PRIORITY = [Document, Binary, self]

    # Load information for an object from a response given by {Riak::Client::HTTPBackend}.
    # Used mostly internally - use {Riak::Bucket#get} to retrieve an {Riak::RObject} instance.
    # @param [Hash] response a response from {Riak::Client::HTTPBackend}
    # @return [Riak::RObject] an appropriate instance of a subclass of {Riak::RObject}
    def self.load(bucket, key, response)
      subclass = SUBCLASS_PRIORITY.find {|k| k.matches?(response[:headers]) }
      subclass.new(bucket, key).load(response)
    end

    # Detect whether this is an appropriate wrapper for the data received from Riak
    # @param [Hash] headers the headers hash received in the response
    # @return [true,false] whether the data should be instantiated as this class
    def self.matches?(headers)
      true
    end

    # @return [Bucket] the bucket in which this object is contained
    attr_accessor :bucket

    # @return [String] the key of this object within its bucket
    attr_accessor :key

    # @return [String] the MIME content type of the object
    attr_accessor :content_type

    # @return [String] the Riak vector clock for the object
    attr_accessor :vclock

    # @return [Object] the data stored in Riak at this object's key. Varies in format by subclass, defaulting to String from the response body.
    attr_accessor :data

    # @return [Array<Link>] an array of {Riak::Link} objects for relationships between this object and other resources
    attr_accessor :links

    # @return [String] the ETag header from the most recent HTTP response, useful for caching and reloading
    attr_accessor :etag

    # @return [Time] the Last-Modified header from the most recent HTTP response, useful for caching and reloading
    attr_accessor :last_modified

    # @return [Hash] a hash of any X-Riak-Meta-* headers that were in the HTTP response, keyed on the trailing portion
    attr_accessor :meta

    # Create a new object manually
    # @param [Bucket] bucket the bucket in which the object exists
    # @param [String] key the key at which the object resides. If nil, a key will be assigned when the object is saved.
    # @see Bucket#get
    def initialize(bucket, key=nil)
      @bucket, @key = bucket, key
    end

    # Load object data from an HTTP response
    # @param [Hash] response a response from {Riak::Client::HTTPBackend}
    def load(response)
      @content_type = response[:headers]['content-type'].try(:first)
      @data = response[:body]
      @vclock = response[:headers]['x-riak-vclock'].try(:first)
      @links = Link.parse(response[:headers]['link'].try(:first) || "")
      @etag = response[:headers]['etag'].try(:first)
      @last_modified = Time.httpdate(response[:headers]['last-modified'].first) if response[:headers]['last-modified']
      @meta = response[:headers].inject({}) do |h,(k,v)|
        if k =~ /x-riak-meta-(.*)/
          h[$1] = v
        end
        h
      end
      self
    end
  end
end
