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
  # The specification of how to follow links from one object to another in Riak,
  # when using the link-walker resource.
  # Example link-walking operation:
  #   GET /riak/artists/REM/albums,_,_/tracks,_,1
  # This operation would have two WalkSpecs:
  #   Riak::WalkSpec.new({:bucket => 'albums'})
  #   Riak::WalkSpec.new({:bucket => 'tracks', :result => true})
  class WalkSpec
    include Util::Translation
    include Util::Escape

    # @return [String] The bucket followed links should be restricted to. "_" represents all buckets.
    attr_accessor :bucket

    # @return [String] The "riaktag" or "rel" that followed links should be restricted to. "_" represents all tags.
    attr_accessor :tag

    # @return [Boolean] Whether objects should be returned from this phase of link walking. Default is false.
    attr_accessor :keep

    # Normalize a list of walk specs into WalkSpec objects.
    def self.normalize(*params)
      params.flatten!
      specs = []
      while params.length > 0
        param = params.shift
        case param
        when Hash
          specs << new(param)
        when WalkSpec
          specs << param
        else
          if params.length >= 2
            specs << new(param, params.shift, params.shift)
          else
            raise ArgumentError, t("too_few_arguments", :params => params.inspect)
          end
        end
      end
      specs
    end

    # Creates a walk-spec for use in finding other objects in Riak.
    # @overload initialize(hash)
    #   Creates a walk-spec from a hash.
    #   @param [Hash] hash options for the walk-spec
    #   @option hash [String] :bucket ("_") the bucket the links should point to (default '_' is all)
    #   @option hash [String] :tag ("_") the tag to filter links by (default '_' is all)
    #   @option hash [Boolean] :keep (false) whether to return results from following this link specification
    # @overload initialize(bucket, tag, keep)
    #   Creates a walk-spec from a bucket-tag-result triple.
    #   @param [String] bucket the bucket the links should point to (default '_' is all)
    #   @param [String] tag the tag to filter links by (default '_' is all)
    #   @param [Boolean] keep whether to return results from following this link specification
    # @see {Riak::RObject#walk}
    def initialize(*args)
      args.flatten!
      case args.size
      when 1
        hash = args.first
        raise ArgumentError, t("hash_type", :hash => hash.inspect) unless Hash === hash
        assign(hash[:bucket], hash[:tag], hash[:keep])
      when 3
        assign(*args)
      else
        raise ArgumentError, t("wrong_argument_count_walk_spec")
      end
    end

    # Converts the walk-spec into the form required by the link-walker resource URL
    def to_s
      b = @bucket && escape(@bucket) || '_'
      t = @tag && escape(@tag) || '_'
      "#{b},#{t},#{@keep ? '1' : '_'}"
    end

    def ==(other)
      other.is_a?(WalkSpec) && other.bucket == bucket && other.tag == tag && other.keep == keep
    end

    def ===(other)
      self == other || case other
                       when WalkSpec
                         other.keep == keep &&
                           (bucket == "_" || bucket == other.bucket) &&
                           (tag == "_" || tag == other.tag)
                       when Link
                         (bucket == "_" || bucket == other.url.split("/")[2]) &&
                           (tag == "_" || tag == other.rel)
                       end
    end

    private
    def assign(bucket, tag, result)
      @bucket = bucket || "_"
      @tag = tag || "_"
      @keep = result || false
    end
  end
end
