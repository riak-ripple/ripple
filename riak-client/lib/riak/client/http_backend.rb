require 'riak/util/escape'
require 'riak/util/translation'
require 'riak/util/multipart'
require 'riak/util/multipart/stream_parser'
require 'riak/json'
require 'riak/client'
require 'riak/bucket'
require 'riak/robject'
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
        get(200, ping_path)
        true
      rescue
        false
      end

      # Fetches an object by bucket/key
      # @param [Bucket, String] bucket the bucket where the object is
      #        stored
      # @param [String] key the key of the object
      # @param [Hash] options request quorums
      # @option options [Fixnum, String, Symbol] :r the read quorum for the
      #   request - how many nodes should concur on the read
      # @option options [Fixnum, String, Symbol] :pr the "primary"
      #   read quorum for the request - how many primary partitions
      #   must be available
      # @return [RObject] the fetched object
      def fetch_object(bucket, key, options={})
        bucket = Bucket.new(client, bucket) if String === bucket
        response = get([200,300], object_path(bucket.name, key, options))
        load_object(RObject.new(bucket, key), response)
      end

      # Reloads the data for a given RObject, a special case of {#fetch_object}.
      def reload_object(robject, options={})
        response = get([200,300,304], object_path(robject.bucket.name, robject.key, options), reload_headers(robject))
        if response[:code].to_i == 304
          robject
        else
          load_object(robject, response)
        end
      end

      # Stores an object
      # @param [RObject] robject the object to store
      # @param [Hash] options quorum and storage options
      # @option options [true,false] :returnbody (false) whether to update the object
      #        after write with the new value
      # @option options [Fixnum, String, Symbol] :w the write quorum
      # @option options [Fixnum, String, Symbol] :pw the "primary"
      #   write quorum - how many primary partitions must be available
      # @option options [Fixnum, String, Symbol] :dw the durable write quorum
      def store_object(robject, options={})
        method, codes = if robject.key.present?
                          [:put, [200,204,300]]
                        else
                          [:post, 201]
                        end
        response = send(method, codes, object_path(robject.bucket.name, robject.key, options), robject.raw_data, store_headers(robject))
        load_object(robject, response) if options[:returnbody]
      end

      # Deletes an object
      # @param [Bucket, String] bucket the bucket where the object
      #    lives
      # @param [String] key the key where the object lives
      # @param [Hash] options quorum and delete options
      # @options options [Fixnum, String, Symbol] :rw the read/write quorum for
      #   the request
      # @options options [String] :vclock the vector clock of the
      #   object to be deleted
      def delete_object(bucket, key, options={})
        bucket = bucket.name if Bucket === bucket
        vclock = options.delete(:vclock)
        headers = vclock ? {"X-Riak-VClock" => vclock} : {}
        delete([204, 404], object_path(bucket, key, options), headers)
      end

      # Fetches bucket properties
      # @param [Bucket, String] bucket the bucket properties to fetch
      # @return [Hash] bucket properties
      def get_bucket_props(bucket)
        bucket = bucket.name if Bucket === bucket
        response = get(200, bucket_properties_path(bucket))
        JSON.parse(response[:body])['props']
      end

      # Sets bucket properties
      # @param [Bucket, String] bucket the bucket to set properties on
      # @param [Hash] properties the properties to set
      def set_bucket_props(bucket, props)
        bucket = bucket.name if Bucket === bucket
        body = {'props' => props}.to_json
        put(204, bucket_properties_path(bucket), body, {"Content-Type" => "application/json"})
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
          get(200, key_list_path(bucket, :keys => 'stream'), {}, &KeyStreamer.new(block))
        else
          response = get(200, key_list_path(bucket))
          obj = JSON.parse(response[:body])
          obj && obj['keys'].map {|k| unescape(k) }
        end
      end

      # Lists known buckets
      # @return [Array<String>] the list of buckets
      def list_buckets
        response = get(200, bucket_list_path)
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
          post(200, mapred_path({:chunked => true}), mr.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"}, &parser)
          nil
        else
          response = post(200, mapred_path, mr.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"})
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
        response = get(200, stats_path)
        JSON.parse(response[:body])
      end

      # Performs a link-walking query
      # @param [RObject] robject the object to start at
      # @param [Array<WalkSpec>] walk_specs a list of walk
      #        specifications to process
      # @return [Array<Array<RObject>>] a list of the matched objects,
      #         grouped by phase
      def link_walk(robject, walk_specs)
        response = get(200, link_walk_path(robject.bucket.name, robject.key, walk_specs))
        if boundary = Util::Multipart.extract_boundary(response[:headers]['content-type'].first)
          Util::Multipart.parse(response[:body], boundary).map do |group|
            group.map do |obj|              
              if obj[:headers] && !obj[:headers]['x-riak-deleted'] && !obj[:body].blank? && obj[:headers]['location']
                link = Riak::Link.new(obj[:headers]['location'].first, "")
                load_object(RObject.new(client.bucket(link.bucket), link.key), obj)
              end
            end.compact
          end
        else
          []
        end
      end

      # Performs a secondary-index query.
      # @param [String, Bucket] bucket the bucket to query
      # @param [String] index the index to query
      # @param [String, Integer, Range] query the equality query or
      #   range query to perform
      # @return [Array<String>] a list of keys matching the query
      def get_index(bucket, index, query)
        bucket = bucket.name if Bucket === bucket
        path = case query
               when Range
                 raise ArgumentError, t('invalid_index_query', :value => query.inspect) unless String === query.begin || Integer === query.end
                 index_range_path(bucket, index, query.begin, query.end)
               when String, Integer
                 index_eq_path(bucket, index, query)
               else
                 raise ArgumentError, t('invalid_index_query', :value => query.inspect)
               end
        response = get(200, path)
        JSON.parse(response[:body])['keys']
      end
    end
  end
end
