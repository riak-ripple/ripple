
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
        # @return [String] a URL path to the "ping" resource
        def ping_path
          path(riak_kv_wm_ping)
        end
        
        # @return [String] a URL path to the "stats" resource
        def stats_path
          path(riak_kv_wm_stats)
        end

        # @return [String] a URL path to the "mapred" resource
        # @param options [Hash] query parameters, e.g. chunked=true
        def mapred_path(options={})
          path(riak_kv_wm_mapred, options)
        end
        
        # @return [String] a URL path for the "buckets list" resource
        def bucket_list_path(options={})
          if new_scheme?
            path(riak_kv_wm_buckets, options.merge(:buckets => true))
          else
            path(riak_kv_wm_raw, options.merge(:buckets => true))
          end
        end

        # @return [String] a URL path for the "bucket properties"
        #   resource
        # @param [String] bucket the bucket name
        def bucket_properties_path(bucket, options={})
          if new_scheme?
            path(riak_kv_wm_buckets, escape(bucket), "props", options)
          else
            path(riak_kv_wm_raw, escape(bucket), options.merge(:props => true, :keys => false))
          end
        end

        # @return [String] a URL path for the "list keys" resource
        # @param [String] bucket the bucket whose keys to list
        # @param [Hash] options query parameters, e.g. keys=stream        
        def key_list_path(bucket, options={:keys => true})
          if new_scheme?
            path(riak_kv_wm_buckets, escape(bucket), "keys", options)
          else
            path(riak_kv_wm_raw, escape(bucket), options.merge(:props => false))
          end
        end

        # @return [String] a URL path for the "object" resource
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

        # @return [String] a URL path for the "link-walking" resource
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
          server_config[:riak_kv_wm_raw] || client.prefix
        end

        def riak_kv_wm_link_walker
          server_config[:riak_kv_wm_link_walker] || client.prefix
        end

        def riak_kv_wm_mapred
          server_config[:riak_kv_wm_mapred] || client.mapred
        end

        def riak_kv_wm_ping
          server_config[:riak_kv_wm_ping] || "/ping"
        end

        def riak_kv_wm_stats
          server_config[:riak_kv_wm_stats] || "/stats"
        end
      end
    end
  end
end
