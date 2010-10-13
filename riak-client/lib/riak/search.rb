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
require 'builder' # Needed to generate Solr XML

module Riak
  class Client
    # @return [String] The URL path prefix to the Solr HTTP endpoint
    attr_accessor :solr

    # @private
    alias :initialize_core :initialize
    # @option options [String] :solr ('/solr') The URL path prefix to the Solr HTTP endpoint
    def initialize(options={})
      self.solr = options.delete(:solr) || "/solr"
      initialize_core(options)
    end

    # Performs a search via the Solr interface.
    # @overload search(index, query, options={})
    #   @param [String] index the index to query on
    #   @param [String] query a Lucene query string
    # @overload search(query, options={})
    #   Queries the default index
    #   @param [String] query a Lucene query string
    # @param [Hash] options extra options for the Solr query
    # @option options [String] :df the default field to search in
    # @option options [String] :'q.op' the default operator between terms ("or", "and")
    # @option options [String] :wt ("json") the response type - "json" and "xml" are valid
    # @option options [String] :sort ('none') the field and direction to sort, e.g. "name asc"
    # @option options [Fixnum] :start (0) the offset into the query to start from, e.g. for pagination
    # @option options [Fixnum] :rows (10) the number of results to return
    # @return [Hash] the query result, containing the 'responseHeaders' and 'response' keys
    def search(*args)
      options = args.extract_options!
      index, query = args[-2], args[-1]  # Allows nil index, while keeping it as first argument
      path = [solr, index, "select", {"q" => query, "wt" => "json"}.merge(options.stringify_keys), {}].compact
      response = http.get(200, *path)
      if response[:headers]['content-type'].include?("application/json")
        ActiveSupport::JSON.decode(response[:body])
      else
        response[:body]
      end
    end
    alias :select :search

    # Adds documents to a search index via the Solr interface.
    # @overload index(index, *docs)
    #   Adds documents to the specified search index
    #   @param [String] index the index in which to add/update the given documents
    #   @param [Array<Hash>] docs unnested document hashes, with one key per field
    # @overload index(*docs)
    #   Adds documents to the default search index
    #   @param [Array<Hash>] docs unnested document hashes, with one key per field
    # @raise [ArgumentError] if any documents don't include 'id' key
    def index(*args)
      index = args.shift if String === args.first # Documents must be hashes of fields
      raise ArgumentError.new(t("search_docs_require_id")) unless args.all? {|d| d.key?("id") || d.key?(:id) }
      xml = Builder::XmlMarkup.new
      xml.add do
        args.each do |doc|
          xml.doc do
            doc.each do |k,v|
              xml.field('name' => k.to_s) { xml.text!(v.to_s) }
            end
          end
        end
      end
      path = [solr, index, "update", xml.target!, {'Content-Type' => 'text/xml'}].compact
      http.post(200, *path)
      true
    end
    alias :add_doc :index

    # Removes documents from a search index via the Solr interface.
    # @overload remove(index, specs)
    #   Removes documents from the specified index
    #   @param [String] index the index from which to remove documents
    #   @param [Array<Hash>] specs the specificaiton of documents to remove (must contain 'id' or 'query' keys)
    # @overload remove(specs)
    #   Removes documents from the default index
    #   @param [Array<Hash>] specs the specification of documents to remove (must contain 'id' or 'query' keys)
    # @raise [ArgumentError] if any document specs don't include 'id' or 'query' keys
    def remove(*args)
      index = args.shift if String === args.first
      raise ArgumentError.new(t("search_remove_requires_id_or_query")) unless args.all? {|s| s.stringify_keys.key?("id") || s.stringify_keys.key?("query") }
      xml = Builder::XmlMarkup.new
      xml.delete do
        args.each do |spec|
          spec.each do |k,v|
            xml.tag!(k.to_sym, v)
          end
        end
      end
      path = [solr, index, "update", xml.target!, {'Content-Type' => 'text/xml'}].compact
      http.post(200, *path)
      true
    end
    alias :delete_doc :remove
    alias :deindex :remove
  end

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
