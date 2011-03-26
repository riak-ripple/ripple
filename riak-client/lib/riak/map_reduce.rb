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
  # Class for invoking map-reduce jobs using the HTTP interface.
  class MapReduce
    include Util::Translation
    include Util::Escape

    autoload :Phase,         "riak/map_reduce/phase"
    autoload :FilterBuilder, "riak/map_reduce/filter_builder"

    # @return [Array<[bucket,key]>,String,Hash<:bucket,:filters>] The
    #       bucket/keys for input to the job, or the bucket (all
    #       keys), or a hash containing the bucket and key-filters.
    # @see #add
    attr_accessor :inputs

    # @return [Array<Phase>] The map and reduce phases that will be executed
    # @see #map
    # @see #reduce
    # @see #link
    attr_accessor :query

    # Creates a new map-reduce job.
    # @param [Client] client the Riak::Client interface
    # @yield [self] helpful for initializing the job
    def initialize(client)
      @client, @inputs, @query = client, [], []
      yield self if block_given?
    end

    # Add or replace inputs for the job.
    # @overload add(bucket)
    #   Run the job across all keys in the bucket.  This will replace any other inputs previously added.
    #   @param [String, Bucket] bucket the bucket to run the job on
    # @overload add(bucket,key)
    #   Add a bucket/key pair to the job.
    #   @param [String,Bucket] bucket the bucket of the object
    #   @param [String] key the key of the object
    # @overload add(object)
    #   Add an object to the job (by its bucket/key)
    #   @param [RObject] object the object to add to the inputs
    # @overload add(bucket, key, keydata)
    #   @param [String,Bucket] bucket the bucket of the object
    #   @param [String] key the key of the object
    #   @param [String] keydata extra data to pass along with the object to the job
    # @overload add(bucket, filters)
    #   Run the job across all keys in the bucket, with the given
    #   key-filters. This will replace any other inputs previously
    #   added. (Requires Riak 0.14)
    #   @param [String,Bucket] bucket the bucket to filter keys from
    #   @param [Array<Array>] filters a list of key-filters to apply
    #                                 to the key list
    # @return [MapReduce] self
    def add(*params)
      params = params.dup
      params = params.first if Array === params.first
      case params.size
      when 1
        p = params.first
        case p
        when Bucket
          @inputs = escape(p.name)
        when RObject
          @inputs << [escape(p.bucket.name), escape(p.key)]
        when String
          @inputs = escape(p)
        end
      when 2..3
        bucket = params.shift
        bucket = bucket.name if Bucket === bucket
        if Array === params.first
          @inputs = {:bucket => escape(bucket), :key_filters => params.first }
        else
          key = params.shift
          @inputs << params.unshift(escape(key)).unshift(escape(bucket))
        end
      end
      self
    end
    alias :<< :add
    alias :include :add

    # Adds a bucket and key-filters built by the given
    # block. Equivalent to #add with a list of filters.
    # @param [String] bucket the bucket to apply key-filters to
    # @yield [] builder block - instance_eval'ed into a FilterBuilder
    # @return [MapReduce] self
    # @see MapReduce#add
    def filter(bucket, &block)
      add(bucket, FilterBuilder.new(&block).to_a)
    end

    # Add a map phase to the job.
    # @overload map(function)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module,function] pair
    # @overload map(function?, options)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module, function] pair
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @return [MapReduce] self
    # @see Phase#initialize
    def map(*params)
      options = params.extract_options!
      @query << Phase.new({:type => :map, :function => params.shift}.merge(options))
      self
    end

    # Add a reduce phase to the job.
    # @overload reduce(function)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module,function] pair
    # @overload reduce(function?, options)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module, function] pair
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @return [MapReduce] self
    # @see Phase#initialize
    def reduce(*params)
      options = params.extract_options!
      @query << Phase.new({:type => :reduce, :function => params.shift}.merge(options))
      self
    end

    # Add a link phase to the job. Link phases follow links attached to objects automatically (a special case of map).
    # @overload link(walk_spec, options={})
    #   @param [WalkSpec] walk_spec a WalkSpec that represents the types of links to follow
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @overload link(bucket, tag, keep, options={})
    #   @param [String, nil] bucket the bucket to limit links to
    #   @param [String, nil] tag the tag to limit links to
    #   @param [Boolean] keep whether to keep results of this phase (overrides the phase options)
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @overload link(options)
    #   @param [Hash] options options for both the walk spec and link phase
    #   @see WalkSpec#initialize
    # @return [MapReduce] self
    # @see Phase#initialize
    def link(*params)
      options = params.extract_options!
      walk_spec_options = options.slice!(:type, :function, :language, :arg) unless params.first
      walk_spec = WalkSpec.normalize(params.shift || walk_spec_options).first
      @query << Phase.new({:type => :link, :function => walk_spec}.merge(options))
      self
    end

    # Sets the timeout for the map-reduce job.
    # @param [Fixnum] value the job timeout, in milliseconds
    def timeout(value)
      @timeout = value
      return self
    end
    alias :timeout= :timeout

    # Convert the job to JSON for submission over the HTTP interface.
    # @return [String] the JSON representation
    def to_json(*a)
      hash = {"inputs" => inputs, "query" => query.map(&:as_json)}
      hash['timeout'] = @timeout.to_i if @timeout
      hash.to_json(*a)
    end

    # Executes this map-reduce job.
    # @overload run
    #   Return the entire collection of results.
    #   @return [Array<Array>] similar to link-walking, each element is
    #     an array of results from a phase where "keep" is true. If there
    #     is only one "keep" phase, only the results from that phase will
    #     be returned.
    # @overload run
    #   Stream the results through the given block without accumulating.
    #   @yield [phase, data] A block to stream results through
    #   @yieldparam [Fixnum] phase the phase from which the results were
    #          generated
    #   @yieldparam [Array] data a list of results from the phase
    #   @return [nil] nothing
    def run(&block)
      raise MapReduceError.new(t("empty_map_reduce_query")) if @query.empty?
      @client.backend.mapred(self, &block)
    rescue FailedRequest => fr
      if fr.server_error? && fr.is_json?
        raise MapReduceError.new(fr.body)
      else
        raise fr
      end
    end
  end
end
