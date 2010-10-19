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
  # Represents and encapsulates operations on a Riak bucket.  You may retrieve a bucket
  # using {Client#bucket}, or create it manually and retrieve its meta-information later.
  class Bucket
    include Util::Translation
    include Util::Escape

    # @return [Riak::Client] the associated client
    attr_reader :client

    # @return [String] the bucket name
    attr_reader :name

    # Create a Riak bucket manually.
    # @param [Client] client the {Riak::Client} for this bucket
    # @param [String] name the name of the bucket
    def initialize(client, name)
      raise ArgumentError, t("client_type", :client => client.inspect) unless Client === client
      raise ArgumentError, t("string_type", :string => name.inspect) unless String === name
      @client, @name, @props = client, name, {}
    end

    # Load information for the bucket from a response given by the {Riak::Client::HTTPBackend}.
    # Used mostly internally - use {Riak::Client#bucket} to get a {Bucket} instance.
    # @param [Hash] response a response from {Riak::Client::HTTPBackend}
    # @return [Bucket] self
    # @see Client#bucket
    def load(response={})
      unless response.try(:[], :headers).try(:[],'content-type').try(:first) =~ /json$/
        raise Riak::InvalidResponse.new({"content-type" => ["application/json"]}, response[:headers], t("loading_bucket", :name => name))
      end
      payload = ActiveSupport::JSON.decode(response[:body])
      @keys = payload['keys'].map {|k| CGI.unescape(k) }  if payload['keys']
      @props = payload['props'] if payload['props']
      self
    end

    # Accesses or retrieves a list of keys in this bucket.
    # If a block is given, keys will be streamed through
    # the block (useful for large buckets). When streaming,
    # results of the operation will not be retained in the local Bucket object.
    # @param [Hash] options extra options
    # @yield [Array<String>] a list of keys from the current chunk
    # @option options [Boolean] :reload (false) If present, will force reloading of the bucket's keys from Riak
    # @return [Array<String>] Keys in this bucket
    def keys(options={})
      if block_given?
        @client.http.get(200, @client.prefix, escape(name), {:props => false, :keys => 'stream'}, {}) do |chunk|
          obj = ActiveSupport::JSON.decode(chunk) rescue {}
          yield obj['keys'].map {|k| CGI.unescape(k) } if obj['keys']
        end
      elsif @keys.nil? || options[:reload]
        response = @client.http.get(200, @client.prefix, escape(name), {:props => false, :keys => true}, {})
        load(response)
      end
      @keys
    end


    # Sets internal properties on the bucket
    # Note: this results in a request to the Riak server!
    # @param [Hash] properties new properties for the bucket
    # @option properties [Fixnum] :n_val (3) The N value (replication factor)
    # @option properties [true,false] :allow_mult (false) Whether to permit object siblings
    # @option properties [true,false] :last_write_wins (false) Whether to ignore vclocks
    # @option properties [Array<Hash>] :precommit ([]) precommit hooks
    # @option properties [Array<Hash>] :postcommit ([])postcommit hooks
    # @option properties [Fixnum,String] :r ("quorum") read quorum (numeric or
    # symbolic)
    # @option properties [Fixnum,String] :w ("quorum") write quorum (numeric or
    # symbolic)
    # @option properties [Fixnum,String] :dw ("quorum") durable write quorum
    # (numeric or symbolic)
    # @option properties [Fixnum,String] :rw ("quorum") delete quorum (numeric or
    # symbolic)
    # @return [Hash] the merged bucket properties
    # @raise [FailedRequest] if the new properties were not accepted by the Riakserver
    # @see #n_value, #allow_mult, #r, #w, #dw, #rw
    def props=(properties)
      raise ArgumentError, t("hash_type", :hash => properties.inspect) unless Hash === properties
      body = {'props' => properties}.to_json
      @client.http.put(204, @client.prefix, escape(name), body, {"Content-Type" => "application/json"})
      @props.merge!(properties)
    end

    # @return [Hash] Internal Riak bucket properties.
    # @see #props=
    def props
      @props
    end
    alias_attribute :properties, :props

    # Retrieve an object from within the bucket.
    # @param [String] key the key of the object to retrieve
    # @param [Hash] options query parameters for the request
    # @option options [Fixnum] :r - the read quorum for the request - how many nodes should concur on the read
    # @return [Riak::RObject] the object
    # @raise [FailedRequest] if the object is not found or some other error occurs
    def get(key, options={})
      code = allow_mult ? [200,300] : 200
      response = @client.http.get(code, @client.prefix, escape(name), escape(key), options, {})
      RObject.new(self, key).load(response)
    end
    alias :[] :get

    # Create a new blank object
    # @param [String] key the key of the new object
    # @return [RObject] the new, unsaved object
    def new(key=nil)
      RObject.new(self, key).tap do |obj|
        obj.content_type = "application/json"
      end
    end

    # Fetches an object if it exists, otherwise creates a new one with the given key
    # @param [String] key the key to fetch or create
    # @return [RObject] the new or existing object
    def get_or_new(key, options={})
      begin
        get(key, options)
      rescue Riak::FailedRequest => fr
        if fr.code.to_i == 404
          new(key)
        else
          raise fr
        end
      end
    end

    # Checks whether an object exists in Riak.
    # @param [String] key the key to check
    # @param [Hash] options quorum options
    # @option options [Fixnum] :r - the read quorum value for the request (R)
    # @return [true, false] whether the key exists in this bucket
    def exists?(key, options={})
      result = client.http.head([200,404], client.prefix, escape(name), escape(key), options, {})
      result[:code] == 200
    end
    alias :exist? :exists?

    # Deletes a key from the bucket
    # @param [String] key the key to delete
    # @param [Hash] options quorum options
    # @option options [Fixnum] :rw - the read/write quorum for the delete
    def delete(key, options={})
      client.http.delete([204,404], client.prefix, escape(name), escape(key), options, {})
    end

    # @return [true, false] whether the bucket allows divergent siblings
    def allow_mult
      props['allow_mult']
    end

    # Set the allow_mult property.  *NOTE* This will result in a PUT request to Riak.
    # @param [true, false] value whether the bucket should allow siblings
    def allow_mult=(value)
      self.props = {'allow_mult' => value}
      value
    end

    # @return [Fixnum] the N value, or number of replicas for this bucket
    def n_value
      props['n_val']
    end
    alias :n_val :n_value
    
    # Set the N value (number of replicas). *NOTE* This will result in a PUT request to Riak.
    # Setting this value after the bucket has objects stored in it may have unpredictable results.
    # @param [Fixnum] value the number of replicas the bucket should keep of each object
    def n_value=(value)
      self.props = {'n_val' => value}
      value
    end
    alias :n_val= :n_value=
    
    [:r,:w,:dw,:rw].each do |q|
      class_eval <<-CODE
        def #{q}
          props["#{q}"]
        end

        def #{q}=(value)
          self.props = {"#{q}" => value}
          value
        end
        CODE
      end

      # @return [String] a representation suitable for IRB and debugging output
      def inspect
        "#<Riak::Bucket #{client.http.path(client.prefix, escape(name)).to_s}#{" keys=[#{keys.join(',')}]" if defined?(@keys)}>"
      end
    end
  end
