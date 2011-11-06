require 'riak/util/translation'
require 'riak/client'
require 'riak/robject'
require 'riak/failed_request'

module Riak
  # Represents and encapsulates operations on a Riak bucket.  You may retrieve a bucket
  # using {Client#bucket}, or create it manually and retrieve its meta-information later.
  class Bucket
    include Util::Translation

    # (Riak Search) The precommit specification for kv/search integration
    SEARCH_PRECOMMIT_HOOK = {"mod" => "riak_search_kv_hook", "fun" => "precommit"}

    # @return [Riak::Client] the associated client
    attr_reader :client

    # @return [String] the bucket name
    attr_reader :name

    # Create a Riak bucket manually.
    # @param [Client] client the {Riak::Client} for this bucket
    # @param [String] name the name of the bucket
    def initialize(client, name)
      raise ArgumentError, t("client_type", :client => client.inspect) unless Client === client
      raise ArgumentError, t("string_type", :string => name.inspect) unless String === name
      @client, @name = client, name
    end

    # Retrieves a list of keys in this bucket.
    # If a block is given, keys will be streamed through
    # the block (useful for large buckets). When streaming,
    # results of the operation will not be returned to the caller.
    # @yield [Array<String>] a list of keys from the current chunk
    # @return [Array<String>] Keys in this bucket
    # @note This operation has serious performance implications and
    #    should not be used in production applications.
    def keys(&block)
      warn(t('list_keys', :backtrace => caller.join("\n    "))) unless Riak.disable_list_keys_warnings
      if block_given?
        @client.list_keys(self, &block)
      else
        @client.list_keys(self)
      end
    end

    # Sets internal properties on the bucket
    # Note: this results in a request to the Riak server!
    # @param [Hash] properties new properties for the bucket
    # @option properties [Fixnum] :n_val (3) The N value (replication factor)
    # @option properties [true,false] :allow_mult (false) Whether to permit object siblings
    # @option properties [true,false] :last_write_wins (false) Whether to ignore vclocks
    # @option properties [Array<Hash>] :precommit ([]) precommit hooks
    # @option properties [Array<Hash>] :postcommit ([])postcommit hooks
    # @option properties [Fixnum,String] :r ("quorum") read quorum (numeric or
    # symbolic)
    # @option properties [Fixnum,String] :w ("quorum") write quorum (numeric or
    # symbolic)
    # @option properties [Fixnum,String] :dw ("quorum") durable write quorum
    # (numeric or symbolic)
    # @option properties [Fixnum,String] :rw ("quorum") delete quorum (numeric or
    # symbolic)
    # @return [Hash] the merged bucket properties
    # @raise [FailedRequest] if the new properties were not accepted by the Riakserver
    # @see #n_value, #allow_mult, #r, #w, #dw, #rw
    def props=(properties)
      raise ArgumentError, t("hash_type", :hash => properties.inspect) unless Hash === properties
      props.merge!(properties)
      @client.set_bucket_props(self, properties)
      props
    end
    alias :'properties=' :'props='

    # @return [Hash] Internal Riak bucket properties.
    # @see #props=
    def props
      @props ||= @client.get_bucket_props(self)
    end
    alias :properties :props

    # Retrieve an object from within the bucket.
    # @param [String] key the key of the object to retrieve
    # @param [Hash] options query parameters for the request
    # @option options [Fixnum] :r - the read quorum for the request - how many nodes should concur on the read
    # @return [Riak::RObject] the object
    # @raise [FailedRequest] if the object is not found or some other error occurs
    def get(key, options={})
      @client.get_object(self, key, options)
    end
    alias :[] :get

    # Create a new blank object
    # @param [String] key the key of the new object
    # @return [RObject] the new, unsaved object
    def new(key=nil)
      RObject.new(self, key).tap do |obj|
        obj.content_type = "application/json"
      end
    end

    # Fetches an object if it exists, otherwise creates a new one with the given key
    # @param [String] key the key to fetch or create
    # @return [RObject] the new or existing object
    def get_or_new(key, options={})
      begin
        get(key, options)
      rescue Riak::FailedRequest => fr
        if fr.not_found?
          new(key)
        else
          raise fr
        end
      end
    end

    # Checks whether an object exists in Riak.
    # @param [String] key the key to check
    # @param [Hash] options quorum options
    # @option options [Fixnum] :r - the read quorum value for the request (R)
    # @return [true, false] whether the key exists in this bucket
    def exists?(key, options={})
      begin
        get(key, options)
        true
      rescue Riak::FailedRequest
        false
      end
    end
    alias :exist? :exists?

    # Deletes a key from the bucket
    # @param [String] key the key to delete
    # @param [Hash] options quorum options
    # @option options [Fixnum] :rw - the read/write quorum for the
    #   delete
    # @option options [String] :vclock - the vector clock of the
    #   object being deleted
    def delete(key, options={})
      client.delete_object(self, key, options)
    end

    # Queries a secondary index on the bucket.
    # @note This will only work if your Riak installation supports 2I.
    # @param [String] index the name of the index
    # @param [String,Integer,Range] query the value of the index, or a
    #   Range of values to query
    # @return [Array<String>] a list of keys that match the index
    #   query
    def get_index(index, query)
      client.get_index(self, index, query)
    end

    # @return [true, false] whether the bucket allows divergent siblings
    def allow_mult
      props['allow_mult']
    end

    # Set the allow_mult property.  *NOTE* This will result in a PUT request to Riak.
    # @param [true, false] value whether the bucket should allow siblings
    def allow_mult=(value)
      self.props = {'allow_mult' => value}
      value
    end

    # @return [Fixnum] the N value, or number of replicas for this bucket
    def n_value
      props['n_val']
    end
    alias :n_val :n_value

    # Set the N value (number of replicas). *NOTE* This will result in a PUT request to Riak.
    # Setting this value after the bucket has objects stored in it may have unpredictable results.
    # @param [Fixnum] value the number of replicas the bucket should keep of each object
    def n_value=(value)
      self.props = {'n_val' => value}
      value
    end
    alias :'n_val=' :'n_value='

    %w(r w dw rw).each do |q|
      define_method(q) { props[q] }
      define_method("#{q}=") { |value|
        self.props = { q => value }
        value
      }
    end

    # (Riak Search) Installs a precommit hook that automatically indexes objects
    # into riak_search.
    def enable_index!
      unless is_indexed?
        self.props = {"precommit" => (props['precommit'] + [SEARCH_PRECOMMIT_HOOK]), "search" => true}
      end
    end

    # (Riak Search) Removes the precommit hook that automatically indexes objects
    # into riak_search.
    def disable_index!
      if is_indexed?
        self.props = {"precommit" => (props['precommit'] - [SEARCH_PRECOMMIT_HOOK]), "search" => false}
      end
    end

    # (Riak Search) Detects whether the bucket is automatically indexed into
    # riak_search.
    # @return [true,false] whether the bucket includes the search indexing hook
    def is_indexed?
      props['search'] == true || props['precommit'].include?(SEARCH_PRECOMMIT_HOOK)
    end

    # @return [String] a representation suitable for IRB and debugging output
    def inspect
      "#<Riak::Bucket {#{name}}#{" keys=[#{keys.join(',')}]" if defined?(@keys)}>"
    end

    # @return [true,false] whether the other is equivalent
    def ==(other)
      Bucket === other && other.client == client && other.name == name
    end
  end
end
