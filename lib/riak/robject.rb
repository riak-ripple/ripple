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
  class RObject; end
end

require 'riak/document'
require 'riak/binary'

module Riak
  # Parent class of all object types supported by ripple. {Riak::RObject} represents
  # the data and metadata stored in a bucket/key pair in the Riak database.
  class RObject
    # The order in which child classes will attempt instantiation when loading a response.
    SUBCLASS_PRIORITY = [Riak::Document, Riak::Binary, self]

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
      extract_header(response, "location", :key) {|v| v.split("/").last }
      extract_header(response, "content-type", :content_type)
      extract_header(response, "x-riak-vclock", :vclock)
      extract_header(response, "link", :links) {|v| Link.parse(v) }
      extract_header(response, "etag", :etag)
      extract_header(response, "last-modified", :last_modified) {|v| Time.httpdate(v) }
      @meta = response[:headers].inject({}) do |h,(k,v)|
        if k =~ /x-riak-meta-(.*)/
          h[$1] = v
        end
        h
      end
      @data = deserialize(response[:body]) if response[:body].present?
      self
    end

    # HTTP header hash that will be sent along when storing the object
    # @return [Hash] hash of HTTP Headers
    def headers
      {}.tap do |hash|
        hash["Content-Type"] = @content_type
        hash["X-Riak-Vclock"] = @vclock if @vclock
        unless @links.blank?
          hash["Link"] = @links.reject {|l| l.rel == "up" }.map(&:to_s).join(", ")
        end
        unless @meta.blank?
          @meta.each do |k,v|
            hash["X-Riak-Meta-#{k}"] = v.to_s
          end
        end
      end
    end

    # Store the object in Riak
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r - the "r" parameter (Read quorum for the implicit read performed when validating the store operation)
    # @option options [Fixnum] :w - the "w" parameter (Write quorum)
    # @option options [Fixnum] :dw - the "dw" parameter (Durable-write quorum)
    # @return [Riak::RObject] self
    def store(options={})
      method, path = @key.present? ? [:put, "#{@bucket.name}/#{@key}"] : [:post, @bucket.name]
      response = @bucket.client.http.send(method, 204, path, options, serialize(data), headers)
      load(response)
    end

    # Reload the object from Riak.  Will use conditional GETs when possible.
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r - the "r" parameter (Read quorum)
    # @return [Riak::RObject] self
    def reload(options={})
      return self unless @key && @vclock
      headers = {}.tap do |h|
        h['If-None-Match'] = @etag if @etag.present?
        h['If-Modified-Since'] = @last_modified.httpdate if @last_modified.present?
      end
      begin
        response = @bucket.client.http.get(200, @bucket.name, @key, options, headers)
        load(response)
      rescue FailedRequest => fr
        raise fr unless fr.code == 304
        self
      end
    end

    alias :fetch :reload

    # Serializes the internal object data for sending to Riak.
    # @abstract Subclasses should redefine this method to provide richer functionality
    # @param [Object] payload the data to serialize, providing internally when storing an object
    def serialize(payload)
      payload.to_s
    end

    # Deserializes the internal object data from a Riak response
    # @abstract Subclasses should redefine this method to provide richer functionality
    # @param [String] body the serialized response body
    def deserialize(body)
      body
    end

    def inspect
      "#<#{self.class.name} #{@bucket.client.http.path(@bucket.name, @key).to_s} [#{@content_type}]:#{@data.inspect}>"
    end

    private
    def extract_header(response, name, attribute=nil)
      if response[:headers][name].present?
        value = response[:headers][name].try(:first)
        value = yield value if block_given?
        send("#{attribute}=", value) if attribute
      end
    end
  end
end
