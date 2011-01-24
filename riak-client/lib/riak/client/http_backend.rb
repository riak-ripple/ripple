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
  class Client
    # The parent class for all backends that connect to Riak via
    # HTTP. This class implements all of the universal backend API
    # methods on behalf of subclasses, which need only implement the
    # {TransportMethods#perform} method for library-specific
    # semantics.
    class HTTPBackend
      autoload :RequestHeaders,   "riak/client/http_backend/request_headers"
      autoload :TransportMethods, "riak/client/http_backend/transport_methods"
      autoload :ObjectMethods,    "riak/client/http_backend/object_methods"
      autoload :Configuration,    "riak/client/http_backend/configuration"

      include TransportMethods
      include ObjectMethods
      include Configuration

      include Util::Escape
      include Util::Translation

      # The Riak::Client that uses this backend
      attr_reader :client

      # Create an HTTPBackend for the Riak::Client.
      # @param [Client] client the client
      def initialize(client)
        raise ArgumentError, t("client_type", :client => client) unless Client === client
        @client = client
      end

      # Pings the server
      # @return [true,false] whether the server is available
      def ping
        get(200, riak_kv_wm_ping, {}, {})
        true
      rescue
        false
      end

      # Fetches an object by bucket/key
      # @param [Bucket, String] bucket the bucket where the object is
      #        stored
      # @param [String] key the key of the object
      # @param [Fixnum, String, Symbol] r the read quorum for the
      #         request - how many nodes should concur on the read
      # @return [RObject] the fetched object
      def fetch_object(bucket, key, r=nil)
        bucket = Bucket.new(client, bucket) if String === bucket
        options = r ? {:r => r} : {}
        response = get([200,300],riak_kv_wm_raw, escape(bucket.name), escape(key), options, {})
        load_object(RObject.new(bucket, key), response)
      end

      # Reloads the data for a given RObject, a special case of {#fetch}.
      def reload_object(robject, r = nil)
        options = r ? {:r => r} : {}
        response = get([200,300,304], riak_kv_wm_raw, escape(robject.bucket.name), escape(robject.key), options, reload_headers(robject))
        if response[:code].to_i == 304
          robject
        else
          load_object(robject, response)
        end
      end

      # Stores an object
      # @param [RObject] robject the object to store
      # @param [true,false] returnbody (false) whether to update the object
      #        after write with the new value
      # @param [Fixnum, String, Symbol] w the write quorum
      # @param [Fixnum, String, Symbol] dw the durable write quorum
      def store_object(robject, returnbody=false, w=nil, dw=nil)
        query = {}.tap do |q|
          q[:returnbody] = returnbody unless returnbody.nil?
          q[:w] = w unless w.nil?
          q[:dw] = dw unless dw.nil?
        end
        method, codes, path = if robject.key.present?
                                [:put, [200,204,300], "#{escape(robject.bucket.name)}/#{escape(robject.key)}"]
                              else
                                [:post, 201, escape(robject.bucket.name)]
                              end
        response = send(method, codes, riak_kv_wm_raw, path, query, robject.raw_data, store_headers(robject))
        load_object(robject, response) if returnbody
      end

      # Deletes an object
      # @param [Bucket, String] bucket the bucket where the object
      #        lives
      # @param [String] key the key where the object lives
      # @param [Fixnum, String, Symbol] rw the read/write quorum for
      #        the request
      def delete_object(bucket, key, rw=nil)
        bucket = bucket.name if Bucket === bucket
        options = rw ? {:rw => rw} : {}
        delete([204, 404], riak_kv_wm_raw, escape(bucket), escape(key), options, {})
      end

      # Fetches bucket properties
      # @param [Bucket, String] bucket the bucket properties to fetch
      # @return [Hash] bucket properties
      def get_bucket_props(bucket)
        bucket = bucket.name if Bucket === bucket
        response = get(200, riak_kv_wm_raw, escape(bucket), {:keys => false, :props => true}, {})
        JSON.parse(response[:body])['props']
      end

      # Sets bucket properties
      # @param [Bucket, String] bucket the bucket to set properties on
      # @param [Hash] properties the properties to set
      def set_bucket_props(bucket, props)
        bucket = bucket.name if Bucket === bucket
        body = {'props' => props}.to_json
        put(204, riak_kv_wm_raw, escape(bucket), body, {"Content-Type" => "application/json"})
      end

      # List keys in a bucket
      # @param [Bucket, String] bucket the bucket to fetch the keys
      #        for
      # @yield [Array<String>] a list of keys from the current
      #        streamed chunk
      # @return [Array<String>] the list of keys, if no block was given
      def list_keys(bucket, &block)
        bucket = bucket.name if Bucket === bucket
        if block_given?
          get(200, riak_kv_wm_raw, escape(bucket), {:props => false, :keys => 'stream'}, {}) do |chunk|
            obj = JSON.parse(chunk) rescue nil
            next unless obj && obj['keys']
            yield obj['keys'].map {|k| unescape(k) }
          end
        else
          response = get(200, riak_kv_wm_raw, escape(bucket), {:props => false, :keys => true}, {})
          obj = JSON.parse(response[:body])
          obj && obj['keys'].map {|k| unescape(k) }
        end
      end

      # Lists known buckets
      # @return [Array<String>] the list of buckets
      def list_buckets
        response = get(200, riak_kv_wm_raw, {:buckets => true}, {})
        JSON.parse(response[:body])['buckets']
      end

      # Performs a MapReduce query.
      # @param [MapReduce] mr the query to perform
      # @yield [Fixnum, Object] the phase number and single result
      #        from the phase
      # @return [Array<Object>] the list of results, if no block was
      #        given
      def mapred(mr)
        if block_given?
          parser = Riak::Util::Multipart::StreamParser.new do |response|
            result = JSON.parse(response[:body])
            yield result['phase'], result['data']
          end
          post(200, riak_kv_wm_mapred, {:chunked => true}, mr.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"}, &parser)
          nil
        else
          response = post(200, riak_kv_wm_mapred, mr.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"})
          begin
            JSON.parse(response[:body])
          rescue
            response
          end
        end
      end

      # Gets health statistics
      # @return [Hash] information about the server, including stats
      def stats
        response = get(200, riak_kv_wm_stats, {}, {})
        JSON.parse(response[:body])
      end

      # Performs a link-walking query
      # @param [RObject] robject the object to start at
      # @param [Array<WalkSpec>] walk_specs a list of walk
      #        specifications to process
      # @return [Array<Array<RObject>>] a list of the matched objects,
      #         grouped by phase
      def link_walk(robject, walk_specs)
        response = get(200, riak_kv_wm_link_walker, escape(robject.bucket.name), escape(robject.key), walk_specs.join("/"))
        if boundary = Util::Multipart.extract_boundary(response[:headers]['content-type'].first)
          Util::Multipart.parse(response[:body], boundary).map do |group|
            group.map do |obj|
              if obj[:headers] && obj[:body] && obj[:headers]['location']
                bucket = $1 if obj[:headers]['location'].first =~ %r{/.*/(.*)/.*$}
                load_object(RObject.new(client.bucket(bucket), nil), obj)
              end
            end
          end
        else
          []
        end
      end
    end
  end
end
