require 'riak'

module Riak
  # Parent class of all object types supported by riak-client. {Riak::Object} represents
  # the data stored in a bucket/key pair in the Riak database.
  class Object
    SUBCLASS_PRIORITY = [Document, Binary, self]
    # Load information for an object from a response given by {Riak::Client::HTTPBackend}.
    # Used mostly internally - use {Riak::Bucket#get} to retrieve an {Riak::Object} instance.
    # @param [Hash] response a response from {Riak::Client::HTTPBackend}
    # @return [Riak::Object] an appropriate instance of a subclass of {Riak::Object}   
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
    
    # @return [String] the MIME content type of the object
    attr_accessor :content_type

    # @return [String] the Riak vector clock for the object
    attr_accessor :vclock
    
    # @return [Object] the data stored in Riak at this object's key. Varies in format by subclass, defaulting to String from the response body.
    attr_accessor :data
    
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
      # load links and other data
      self
    end
  end
end
