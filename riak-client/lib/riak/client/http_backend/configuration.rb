
require 'riak/failed_request'
require 'riak/client/http_backend'
require 'riak/link'

module Riak
  class Client
    class HTTPBackend
      # Riak 0.14 provides a root URL that enumerates all of the
      # HTTP endpoints and their paths.  This module adds methods to
      # auto-discover those endpoints via the root URL. It also adds
      # methods for generating URL paths for specific resources.
      module Configuration
        # @return [URI] a URL path to the "ping" resource
        def ping_path
          path(riak_kv_wm_ping)
        end

        # @return [URI] a URL path to the "stats" resource
        def stats_path
          path(riak_kv_wm_stats)
        end

        # @return [URI] a URL path to the "mapred" resource
        # @param options [Hash] query parameters, e.g. chunked=true
        def mapred_path(options={})
          path(riak_kv_wm_mapred, options)
        end

        # @return [URI] a URL path for the "buckets list" resource
        def bucket_list_path(options={})
          if new_scheme?
            path(riak_kv_wm_buckets, options.merge(:buckets => true))
          else
            path(riak_kv_wm_raw, options.merge(:buckets => true))
          end
        end

        # @return [URI] a URL path for the "bucket properties"
        #   resource
        # @param [String] bucket the bucket name
        def bucket_properties_path(bucket, options={})
          if new_scheme?
            path(riak_kv_wm_buckets, escape(bucket), "props", options)
          else
            path(riak_kv_wm_raw, escape(bucket), options.merge(:props => true, :keys => false))
          end
        end

        # @return [URI] a URL path for the "list keys" resource
        # @param [String] bucket the bucket whose keys to list
        # @param [Hash] options query parameters, e.g. keys=stream
        def key_list_path(bucket, options={:keys => true})
          if new_scheme?
            path(riak_kv_wm_buckets, escape(bucket), "keys", options)
          else
            path(riak_kv_wm_raw, escape(bucket), options.merge(:props => false))
          end
        end

        # @return [URI] a URL path for the "object" resource
        # @param [String] bucket the bucket of the object
        # @param [String,nil] key the key of the object, or nil for a
        #   server-assigned key when using POST
        def object_path(bucket, key, options={})
          key = escape(key) if key
          if new_scheme?
            path([riak_kv_wm_buckets, escape(bucket), "keys", key, options].compact)
          else
            path([riak_kv_wm_raw, escape(bucket), key, options].compact)
          end
        end

        # @return [URI] a URL path for the "link-walking" resource
        # @param [String] bucket the bucket of the origin object
        # @param [String] key the key of the origin object
        # @param [Array<WalkSpec>] specs a list of walk specifications
        #   to traverse
        def link_walk_path(bucket, key, specs)
          specs = specs.map {|s| s.to_s }
          if new_scheme?
            path(riak_kv_wm_buckets, escape(bucket), "keys", escape(key), *specs)
          else
            path(riak_kv_wm_link_walker, escape(bucket), escape(key), *specs)
          end
        end

        # @return [URI] a URL path for the "index range query"
        #   resource
        # @param [String] bucket the bucket whose index to query
        # @param [String] index the name of the index to query
        # @param [String,Integer] start the start of the range
        # @param [String,Integer] finish the end of the range
        def index_range_path(bucket, index, start, finish, options={})
          raise t('indexes_unsupported') unless new_scheme?
          path(riak_kv_wm_buckets, escape(bucket), "index", escape(index), escape(start.to_s), escape(finish.to_s), options)
        end

        # @return [URI] a URL path for the "index range query"
        #   resource
        # @param [String] bucket the bucket whose index to query
        # @param [String] index the name of the index to query
        # @param [String,Integer] start the start of the range
        # @param [String,Integer] finish the end of the range
        def index_eq_path(bucket, index, value, options={})
          raise t('indexes_unsupported') unless new_scheme?
          path(riak_kv_wm_buckets, escape(bucket), "index", escape(index), escape(value.to_s), options)
        end

        # @return [URI] a URL path for a Solr query resource
        # @param [String] index the index to query
        # @param [String] query the Lucene-style query string
        # @param [Hash] options additional query options
        def solr_select_path(index, query, options={})
          raise t('search_unsupported') unless riak_solr_searcher_wm
          options = {"q" => query, "wt" => "json"}.merge(options)
          if index
            path(riak_solr_searcher_wm, index, 'select', options)
          else
            path(riak_solr_searcher_wm, 'select', options)
          end
        end

        # @return [URI] a URL path for a Solr update resource
        # @param [String] index the index to update
        def solr_update_path(index)
          raise t('search_unsupported') unless riak_solr_indexer_wm
          if index
            path(riak_solr_indexer_wm, index, 'update')
          else
            path(riak_solr_indexer_wm, 'update')
          end
        end

        # @return [URI] a URL path for the Luwak interface
        def luwak_path(key)
          raise t('luwak_unsupported') unless luwak_wm_file
          if key
            path(luwak_wm_file, escape(key))
          else
            path(luwak_wm_file)
          end
        end

        private
        def server_config
          @server_config ||= {}.tap do |hash|
            begin
              response = get(200, path("/"))
              Link.parse(response[:headers]['link'].first).each {|l| hash[l.tag.intern] ||= l.url }
            rescue Riak::FailedRequest
            end
          end
        end

        def new_scheme?
          !riak_kv_wm_buckets.nil?
        end

        def riak_kv_wm_buckets
          server_config[:riak_kv_wm_buckets]
        end

        def riak_kv_wm_raw
          server_config[:riak_kv_wm_raw] || node.http_paths[:prefix]
        end

        def riak_kv_wm_link_walker
          server_config[:riak_kv_wm_link_walker] || node.http_paths[:prefix]
        end

        def riak_kv_wm_mapred
          server_config[:riak_kv_wm_mapred] || node.http_paths[:mapred]
        end

        def riak_kv_wm_ping
          server_config[:riak_kv_wm_ping] || "/ping"
        end

        def riak_kv_wm_stats
          server_config[:riak_kv_wm_stats] || "/stats"
        end

        def riak_solr_searcher_wm
          server_config[:riak_solr_searcher_wm]
        end

        def riak_solr_indexer_wm
          server_config[:riak_solr_indexer_wm]
        end

        def luwak_wm_file
          server_config[:luwak_wm_file]
        end
      end
    end
  end
end
