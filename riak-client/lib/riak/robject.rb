require 'set'
require 'time'
require 'yaml'
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/bucket'
require 'riak/link'
require 'riak/walk_spec'

module Riak
  # Represents the data and metadata stored in a bucket/key pair in
  # the Riak database, the base unit of data manipulation.
  class RObject
    include Util::Translation
    include Util::Escape
    extend Util::Escape

    # @return [Bucket] the bucket in which this object is contained
    attr_accessor :bucket

    # @return [String] the key of this object within its bucket
    attr_accessor :key

    # @return [String] the MIME content type of the object
    attr_accessor :content_type

    # @return [String] the Riak vector clock for the object
    attr_accessor :vclock

    # @return [Set<Link>] a Set of {Riak::Link} objects for relationships between this object and other resources
    attr_accessor :links

    # @return [String] the ETag header from the most recent HTTP response, useful for caching and reloading
    attr_accessor :etag

    # @return [Time] the Last-Modified header from the most recent HTTP response, useful for caching and reloading
    attr_accessor :last_modified

    # @return [Hash] a hash of any X-Riak-Meta-* headers that were in the HTTP response, keyed on the trailing portion
    attr_accessor :meta

    # @return [Boolean] whether to attempt to prevent stale writes using conditional PUT semantics, If-None-Match: * or If-Match: {#etag}
    # @see http://wiki.basho.com/display/RIAK/REST+API#RESTAPI-Storeaneworexistingobjectwithakey Riak Rest API Docs
    attr_accessor :prevent_stale_writes

    # Loads a list of RObjects that were emitted from a MapReduce
    # query.
    # @param [Client] client A Riak::Client with which the results will be associated
    # @param [Array<Hash>] response A list of results a MapReduce job. Each entry should contain these keys: bucket, key, vclock, values
    # @return [Array<RObject>] An array of RObject instances
    def self.load_from_mapreduce(client, response)
      response.map do |item|
        RObject.new(client[unescape(item['bucket'])], unescape(item['key'])).load_from_mapreduce(item)
      end
    end

    # Create a new object manually
    # @param [Bucket] bucket the bucket in which the object exists
    # @param [String] key the key at which the object resides. If nil, a key will be assigned when the object is saved.
    # @yield self the new RObject
    # @see Bucket#get
    def initialize(bucket, key=nil)
      @bucket, @key = bucket, key
      @links, @meta = Set.new, {}
      yield self if block_given?
    end

    # Load object data from a map/reduce response item.
    # This method is used by RObject::load_from_mapreduce to instantiate the necessary
    # objects.
    # @param [Hash] response a response from {Riak::MapReduce}
    # @return [RObject] self
    def load_from_mapreduce(response)
      self.vclock = response['vclock']
      if response['values'].size == 1
        value = response['values'].first
        load_map_reduce_value(value)
      else
        @conflict = true
        @siblings = response['values'].map do |v|
          RObject.new(self.bucket, self.key) do |robj|
            robj.vclock = self.vclock
            robj.load_map_reduce_value(v)
          end
        end
      end
      self
    end

    # @return [Object] the unmarshaled form of {#raw_data} stored in riak at this object's key
    def data
      if @raw_data && !@data
        @data = deserialize(@raw_data)
        @raw_data = nil
      end
      @data
    end

    # @param [Object] unmarshaled form of the data to be stored in riak. Object will be serialized using {#serialize} if a known content_type is used. Setting this overrides values stored with {#raw_data=}
    # @return [Object] the object stored
    def data=(new_data)
      @raw_data = nil
      @data = new_data
    end

    # @return [String] raw data stored in riak for this object's key
    def raw_data
      if @data && !@raw_data
        @raw_data = serialize(@data)
        @data = nil
      end
      @raw_data
    end

    # @param [String, IO-like] the raw data to be stored in riak at this key, will not be marshaled or manipulated prior to storage. Overrides any data stored by {#data=}
    # @return [String] the data stored
    def raw_data=(new_raw_data)
      @data = nil
      @raw_data = new_raw_data
    end

    # Store the object in Riak
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r the "r" parameter (Read quorum for the implicit read performed when validating the store operation)
    # @option options [Fixnum] :w the "w" parameter (Write quorum)
    # @option options [Fixnum] :dw the "dw" parameter (Durable-write quorum)
    # @option options [Boolean] :returnbody (true) whether to return the result of a successful write in the body of the response. Set to false for fire-and-forget updates, set to true to immediately have access to the object's stored representation.
    # @return [Riak::RObject] self
    # @raise [ArgumentError] if the content_type is not defined
    def store(options={})
      raise ArgumentError, t("content_type_undefined") unless @content_type.present?
      params = {:returnbody => true}.merge(options)
      @bucket.client.backend.store_object(self, params[:returnbody], params[:w], params[:dw])
      self
    end

    # Reload the object from Riak.  Will use conditional GETs when possible.
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r the "r" parameter (Read quorum)
    # @option options [Boolean] :force will force a reload request if
    #     the vclock is not present, useful for reloading the object after
    #     a store (not passed in the query params)
    # @return [Riak::RObject] self
    def reload(options={})
      force = options.delete(:force)
      return self unless @key && (@vclock || force)
      self.etag = self.last_modified = nil if force
      bucket.client.backend.reload_object(self, options[:r])
    end

    alias :fetch :reload

    # Delete the object from Riak and freeze this instance.  Will work whether or not the object actually
    # exists in the Riak database.
    def delete(options={})
      return if key.blank?
      @bucket.delete(key, options)
      freeze
    end

    attr_writer :siblings, :conflict

    # Returns sibling objects when in conflict.
    # @return [Array<RObject>] an array of conflicting sibling objects for this key
    # @return [self] this object when not in conflict
    def siblings
      return self unless conflict?
      @siblings
    end

    # @return [true,false] Whether this object has conflicting sibling objects (divergent vclocks)
    def conflict?
      @conflict.present?
    end

    # Serializes the internal object data for sending to Riak. Differs based on the content-type.
    # This method is called internally when storing the object.
    # Automatically serialized formats:
    # * JSON (application/json)
    # * YAML (text/yaml)
    # * Marshal (application/x-ruby-marshal)
    # When given an IO-like object (e.g. File), no serialization will
    # be done.
    # @param [Object] payload the data to serialize
    def serialize(payload)
      return payload if payload.respond_to?(:read)
      case @content_type
      when /json/
        payload.to_json(Riak.json_options)
      when /yaml/
        YAML.dump(payload)
      when "application/x-ruby-marshal"
        Marshal.dump(payload)
      else
        payload.to_s
      end
    end

    # Deserializes the internal object data from a Riak response. Differs based on the content-type.
    # This method is called internally when loading the object.
    # Automatically deserialized formats:
    # * JSON (application/json)
    # * YAML (text/yaml)
    # * Marshal (application/x-ruby-marshal)
    # @param [String] body the serialized response body
    def deserialize(body)
      case @content_type
      when /json/
        JSON.parse(body)
      when /yaml/
        YAML.load(body)
      when "application/x-ruby-marshal"
        Marshal.load(body)
      else
        body
      end
    end

    # @return [String] A representation suitable for IRB and debugging output
    def inspect
      body = if @data || content_type =~ /json|yaml|marshal/
               data.inspect
             else
               @raw_data && "(#{@raw_data.size} bytes)"
             end
      "#<#{self.class.name} {#{bucket.name}#{"," + @key if @key}} [#{@content_type}]:#{body}>"
    end

    # Walks links from this object to other objects in Riak.
    # @param [Array<Hash,WalkSpec>] link specifications for the query
    def walk(*params)
      specs = WalkSpec.normalize(*params)
      @bucket.client.http.link_walk(self, specs)
    end

    # Converts the object to a link suitable for linking other objects
    # to it
    # @param [String] tag the tag to apply to the link
    def to_link(tag)
      Link.new(@bucket.name, @key, tag)
    end

    # Generates a URL representing the object according to the client, bucket and key.
    # If the key is blank, the bucket URL will be returned (where the object will be
    # submitted to when stored).
    def url
      segments = [ @bucket.client.prefix, escape(@bucket.name)]
      segments << escape(@key) if @key
      @bucket.client.http.path(*segments).to_s
    end

    alias :vector_clock :vclock
    alias :vector_clock= :vclock=

      protected
    def load_map_reduce_value(hash)
      metadata = hash['metadata']
      extract_if_present(metadata, 'X-Riak-VTag', :etag)
      extract_if_present(metadata, 'content-type', :content_type)
      extract_if_present(metadata, 'X-Riak-Last-Modified', :last_modified) { |v| Time.httpdate( v ) }
      extract_if_present(metadata, 'Links', :links) do |links|
        Set.new( links.map { |l| Link.new(*l) } )
      end
      extract_if_present(metadata, 'X-Riak-Meta', :meta) do |meta|
        Hash[
             meta.map do |k,v|
               [k.sub(%r{^x-riak-meta-}i, ''), [v]]
             end
            ]
      end
      extract_if_present(hash, 'data', :data) { |v| deserialize(v) }
    end

    private
    def extract_if_present(hash, key, attribute=nil)
      if hash[key].present?
        attribute ||= key
        value = block_given? ? yield(hash[key]) : hash[key]
        send("#{attribute}=", value)
      end
    end
  end
end
