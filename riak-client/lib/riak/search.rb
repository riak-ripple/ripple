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
require 'riak/client'
require 'riak/bucket'
require 'riak/map_reduce'

module Riak
  class Bucket
    # The precommit specification for kv/search integration
    SEARCH_PRECOMMIT_HOOK = {"mod" => "riak_search_kv_hook", "fun" => "precommit"}

    # Installs a precommit hook that automatically indexes objects
    # into riak_search.
    def enable_index!
      unless is_indexed?
        self.props = {"precommit" => (props['precommit'] + [SEARCH_PRECOMMIT_HOOK])}
      end
    end

    # Removes the precommit hook that automatically indexes objects
    # into riak_search.
    def disable_index!
      if is_indexed?
        self.props = {"precommit" => (props['precommit'] - [SEARCH_PRECOMMIT_HOOK])}
      end
    end

    # Detects whether the bucket is automatically indexed into
    # riak_search.
    # @return [true,false] whether the bucket includes the search indexing hook
    def is_indexed?
      props['precommit'].include?(SEARCH_PRECOMMIT_HOOK)
    end
  end

  class MapReduce
    # Use a search query to start a map/reduce job.
    # @param [String, Bucket] bucket the bucket/index to search
    # @param [String] query the query to run
    # @return [MapReduce] self
    def search(bucket, query)
      bucket = bucket.name if bucket.respond_to?(:name)
      @inputs = {:module => "riak_search", :function => "mapred_search", :arg => [bucket, query]}
      self
    end
  end
end
