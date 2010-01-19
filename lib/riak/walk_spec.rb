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
  #   GET /raw/artists/REM/albums,_,_/tracks,_,1
  # This operation would have two WalkSpecs:
  #   Riak::WalkSpec.new({:bucket => 'albums'})
  #   Riak::WalkSpec.new({:bucket => 'tracks', :result => true})
  class WalkSpec
    # @return [String] The bucket followed links should be restricted to. "_" represents all buckets.
    attr_accessor :bucket
    
    # @return [String] The "riaktag" or "rel" that followed links should be restricted to. "_" represents all tags.
    attr_accessor :tag
    
    # @return [Boolean] Whether objects should be returned from this phase of link walking. Default is false.
    attr_accessor :result
    
    # Creates a walk-spec for use in finding other objects in Riak.
    # @overload initialize(hash)
    #   Creates a walk-spec from a hash.
    #   @param [Hash] hash options for the walk-spec
    #   @option hash [String] :bucket ("_") the bucket the links should point to (default '_' is all)
    #   @option hash [String] :tag ("_") the tag to filter links by (default '_' is all)
    #   @option hash [Boolean] :result (false) whether to return results from following this link specification
    # @overload initialize(bucket, tag, result)
    #   Creates a walk-spec from a bucket-tag-result triple.
    #   @param [String] bucket the bucket the links should point to (default '_' is all)
    #   @param [String] tag the tag to filter links by (default '_' is all)
    #   @param [Boolean] result whether to return results from following this link specification
    # @see {Riak::RObject#walk}
    def initialize(*args)
      args.flatten!
      case args.size
      when 1
        hash = args.first
        raise ArgumentError, "invalid argument #{hash.inspect}" unless Hash === hash
        assign(hash[:bucket], hash[:tag], hash[:result])
      when 3
        assign(*args)
      else
        raise ArgumentError, "wrong number of arguments (one Hash or bucket,tag,result required)"
      end
    end
    
    # Converts the walk-spec into the form required by the link-walker resource URL
    def to_s
      "#{@bucket || '_'},#{@tag || '_'},#{@result ? '1' : '_'}"
    end
    
    private
    def assign(bucket, tag, result)
      @bucket = bucket || "_"
      @tag = tag || "_"
      @result = result || false
    end
  end
end
