
require 'riak/failed_request'
require 'riak/client/http_backend'
require 'riak/link'

module Riak
  class Client
    class HTTPBackend
      # Riak 0.14 provides a root URL that enumerates all of the
      # HTTP endpoints and their paths.  This module adds methods to
      # auto-discover those endpoints via the root URL.
      module Configuration
        private
        def server_config
          @server_config ||= {}.tap do |hash|
            begin
              response = get(200, "/", {}, {})
              Link.parse(response[:headers]['link'].first).each {|l| hash[l.tag.intern] = l.url }
            rescue Riak::FailedRequest
            end
          end
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
