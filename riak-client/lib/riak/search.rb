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
require 'riak/map_reduce'

module Riak
  # class Client
  #   # Add search stuff here
  # end
  
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
