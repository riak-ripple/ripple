require 'riak/util/escape'
require 'riak/util/translation'
require 'riak/util/multipart'
require 'riak/util/multipart/stream_parser'
require 'riak/json'
require 'riak/client'
require 'riak/bucket'
require 'riak/robject'
require 'riak/client/retryable'
require 'riak/client/http_backend/transport_methods'
require 'riak/client/http_backend/object_methods'
require 'riak/client/http_backend/configuration'
require 'riak/client/http_backend/key_streamer'

module Riak
  class Client
    # The parent class for all backends that connect to Riak via
    # HTTP. This class implements all of the universal backend API
    # methods on behalf of subclasses, which need only implement the
    # {TransportMethods#perform} method for library-specific
    # semantics.
    class HTTPBackend
      include Util::Escape
      include Util::Translation

      include TransportMethods
      include ObjectMethods
      include Configuration
      include Retryable

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
      def ping(options={})
        with_retries(options) do
          get(200, riak_kv_wm_ping, {}, {})
          true
        end
      rescue => e
        false
      end

      # Fetches an object by bucket/key
      # @param [Bucket, String] bucket the bucket where the object is
      #        stored
      # @param [String] key the key of the object
      # @param [Fixnum, String, Symbol] r the read quorum for the
      #         request - how many nodes should concur on the read
      # @return [RObject] the fetched object
      def fetch_object(bucket, key, r=nil, options={})
        bucket = Bucket.new(client, bucket) if String === bucket
        options = r ? {:r => r} : {}
        response = with_retries(options) do
          get([200,300],riak_kv_wm_raw, escape(bucket.name), escape(key), options, {})
        end
        load_object(RObject.new(bucket, key), response)
      end

      # Reloads the data for a given RObject, a special case of {#fetch_object}.
      def reload_object(robject, r = nil, options={})
        options = r ? {:r => r} : {}
        response = with_retries(options) do
          get([200,300,304], riak_kv_wm_raw, escape(robject.bucket.name), escape(robject.key), options, reload_headers(robject))
        end
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
      def store_object(robject, returnbody=false, w=nil, dw=nil, options={})
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
        response = with_retries(options) do
          send(method, codes, riak_kv_wm_raw, path, query, robject.raw_data, store_headers(robject))
        end
        load_object(robject, response) if returnbody
      end

      # Deletes an object
      # @param [Bucket, String] bucket the bucket where the object
      #        lives
      # @param [String] key the key where the object lives
      # @param [Fixnum, String, Symbol] rw the read/write quorum for
      #        the request
      def delete_object(bucket, key, rw=nil, options={})
        bucket = bucket.name if Bucket === bucket
        options = rw ? {:rw => rw} : {}
        with_retries({:codes => [500, 503]}.merge(options)) do
          delete([204, 404], riak_kv_wm_raw, escape(bucket), escape(key), options, {})
        end
      end

      # Fetches bucket properties
      # @param [Bucket, String] bucket the bucket properties to fetch
      # @return [Hash] bucket properties
      def get_bucket_props(bucket, options={})
        bucket = bucket.name if Bucket === bucket
        response = with_retries(options) do
          get(200, riak_kv_wm_raw, escape(bucket), {:keys => false, :props => true}, {})
        end
        JSON.parse(response[:body])['props']
      end

      # Sets bucket properties
      # @param [Bucket, String] bucket the bucket to set properties on
      # @param [Hash] properties the properties to set
      def set_bucket_props(bucket, props, options={})
        bucket = bucket.name if Bucket === bucket
        body = {'props' => props}.to_json
        with_retries(options) do
          put(204, riak_kv_wm_raw, escape(bucket), body, {"Content-Type" => "application/json"})
        end
      end

      # List keys in a bucket
      # @param [Bucket, String] bucket the bucket to fetch the keys
      #        for
      # @yield [Array<String>] a list of keys from the current
      #        streamed chunk
      # @return [Array<String>] the list of keys, if no block was given
      def list_keys(bucket, options={}, &block)
        bucket = bucket.name if Bucket === bucket
        if block_given?
          with_retries(options) do
            get(200, riak_kv_wm_raw, escape(bucket), {:props => false, :keys => 'stream'}, {}, &KeyStreamer.new(block))
          end
        else
          response = with_retries(options) do
            get(200, riak_kv_wm_raw, escape(bucket), {:props => false, :keys => true}, {})
          end
          obj = JSON.parse(response[:body])
          obj && obj['keys'].map {|k| unescape(k) }
        end
      end

      # Lists known buckets
      # @return [Array<String>] the list of buckets
      def list_buckets(options={})
        response = with_retries({:retries => 1}.merge(options)) do
          get(200, riak_kv_wm_raw, {:buckets => true}, {})
        end
        JSON.parse(response[:body])['buckets']
      end

      # Performs a MapReduce query.
      # @param [MapReduce] mr the query to perform
      # @yield [Fixnum, Object] the phase number and single result
      #        from the phase
      # @return [Array<Object>] the list of results, if no block was
      #        given
      def mapred(mr, options={})
        if block_given?
          parser = Riak::Util::Multipart::StreamParser.new do |response|
            result = JSON.parse(response[:body])
            yield result['phase'], result['data']
          end
          with_retries({:retries => 1}.merge(options)) do
            post(200, riak_kv_wm_mapred, {:chunked => true}, mr.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"}, &parser)
          end
          nil
        else
          response = with_retries({:retries => 1}.merge(options)) do
            post(200, riak_kv_wm_mapred, mr.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"})
          end
          begin
            JSON.parse(response[:body])
          rescue
            response
          end
        end
      end

      # Gets health statistics
      # @return [Hash] information about the server, including stats
      def stats(options={})
        response = with_retries(options) do
          get(200, riak_kv_wm_stats, {}, {})
        end
        JSON.parse(response[:body])
      end

      # Performs a link-walking query
      # @param [RObject] robject the object to start at
      # @param [Array<WalkSpec>] walk_specs a list of walk
      #        specifications to process
      # @return [Array<Array<RObject>>] a list of the matched objects,
      #         grouped by phase
      def link_walk(robject, walk_specs, options={})
        response = with_retries({:retries => 1}.merge(options)) do
          get(200, riak_kv_wm_link_walker, escape(robject.bucket.name), escape(robject.key), walk_specs.join("/"))
        end
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

      private
      RETRYABLE_EXCEPTIONS = []

      def retryable?(exception, options={})
        codes = options[:codes] || [404, 500, 503]
        exceptions = options[:exceptions] || RETRYABLE_EXCEPTIONS
        (HTTPFailedRequest === exception && codes.include?(exception.code)) ||
          exceptions.include?(exception)
      end
    end
  end
end
