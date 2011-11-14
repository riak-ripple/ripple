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

      # The Riak::Client::Node that uses this backend
      attr_reader :node

      # Create an HTTPBackend for the Riak::Client.
      # @param [Client] The client
      # @param [Node] The node we're connecting to.
      def initialize(client, node)
        raise ArgumentError, t("client_type", :client => client) unless Client === client
        raise ArgumentError, t("node_type", :node => node) unless Node === node
        @client = client
        @node = node
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

      # (Riak Search) Performs a search query
      # @param [String,nil] index the index to query, or nil for the
      #   default
      # @param [String] query the Lucene query to perform
      # @param [Hash] options query options
      # @see Client#search
      def search(index, query, options={})
        response = get(200, solr_select_path(index, query, options.stringify_keys))
        if response[:headers]['content-type'].include?("application/json")
          JSON.parse(response[:body])
        else
          response[:body]
        end
      end

      # (Riak Search) Updates a search index (includes deletes).
      # @param [String, nil] index the index to update, or nil for the
      #   default index.
      # @param [String] updates an XML update string in Solr's required format
      # @see Client#index
      def update_search_index(index, updates)
        post(200, solr_update_path(index), updates, {'Content-Type' => 'text/xml'})
      end

      # (Luwak) Fetches a file from the Luwak large-file interface.
      # @param [String] filename the name of the file
      # @yield [chunk] A block which will receive individual chunks of
      #   the file as they are streamed
      # @yieldparam [String] chunk a block of the file
      # @return [IO, nil] the file (also having content_type and
      #   original_filename accessors). The file will need to be
      #   reopened to be read
      def get_file(filename, &block)
        if block_given?
          get(200, luwak_path(filename), &block)
          nil
        else
          tmpfile = LuwakFile.new(escape(filename))
          begin
            response = get(200, luwak_path(filename)) do |chunk|
              tmpfile.write chunk
            end
            tmpfile.content_type = response[:headers]['content-type'].first
            tmpfile
          ensure
            tmpfile.close
          end
        end
      end

      # (Luwak) Detects whether a file exists in the Luwak large-file
      # interface.
      # @param [String] filename the name of the file
      # @return [true,false] whether the file exists
      def file_exists?(filename)
        result = head([200,404], luwak_path(filename))
        result[:code] == 200
      end

      # (Luwak) Deletes a file from the Luwak large-file interface.
      # @param [String] filename the name of the file
      def delete_file(filename)
        delete([204,404], luwak_path(filename))
      end

      # (Luwak) Uploads a file to the Luwak large-file interface.
      # @overload store_file(filename, content_type, data)
      #   Stores the file at the given key/filename
      #   @param [String] filename the key/filename for the object
      #   @param [String] content_type the MIME Content-Type for the data
      #   @param [IO, String] data the contents of the file
      # @overload store_file(content_type, data)
      #   Stores the file with a server-determined key/filename
      #   @param [String] content_type the MIME Content-Type for the data
      #   @param [String, #read] data the contents of the file
      # @return [String] the key/filename where the object was stored
      def store_file(*args)
        data, content_type, filename = args.reverse
        if filename
          put(204, luwak_path(filename), data, {"Content-Type" => content_type})
          filename
        else
          response = post(201, luwak_path(nil), data, {"Content-Type" => content_type})
          response[:headers]["location"].first.split("/").last
        end
      end
    end
  end
end
