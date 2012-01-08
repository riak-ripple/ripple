require 'riak'
require 'socket'
require 'base64'
require 'digest/sha1'
require 'riak/util/translation'

module Riak
  class Client
    class ProtobuffsBackend
      include Util::Translation
      include Util::Escape

      # Message Codes Enum
      MESSAGE_CODES = %W[
          ErrorResp
          PingReq
          PingResp
          GetClientIdReq
          GetClientIdResp
          SetClientIdReq
          SetClientIdResp
          GetServerInfoReq
          GetServerInfoResp
          GetReq
          GetResp
          PutReq
          PutResp
          DelReq
          DelResp
          ListBucketsReq
          ListBucketsResp
          ListKeysReq
          ListKeysResp
          GetBucketReq
          GetBucketResp
          SetBucketReq
          SetBucketResp
          MapRedReq
          MapRedResp
       ].map {|s| s.intern }.freeze

      def self.simple(method, code)
        define_method method do
          socket.write([1, MESSAGE_CODES.index(code)].pack('NC'))
          decode_response
        end
      end

      attr_accessor :client
      attr_accessor :node
      def initialize(client, node)
        @client = client
        @node = node
      end

      simple :ping,          :PingReq
      simple :get_client_id, :GetClientIdReq
      simple :server_info,   :GetServerInfoReq
      simple :list_buckets,  :ListBucketsReq

      # Performs a secondary-index query via emulation through MapReduce.
      # @param [String, Bucket] bucket the bucket to query
      # @param [String] index the index to query
      # @param [String, Integer, Range] query the equality query or
      #   range query to perform
      # @return [Array<String>] a list of keys matching the query
      def get_index(bucket, index, query)
        mapred(Riak::MapReduce.new(client).
               index(bucket, index, query).
               reduce(%w[riak_kv_mapreduce reduce_identity], :arg => {:reduce_phase_only_1 => true}, :keep => true)).map {|p| p.last }
      end

      # Gracefully shuts down this connection.
      def teardown
        reset_socket
      end

      private
      # Implemented by subclasses
      def decode_response
        raise NotImplementedError
      end

      def socket
        @socket ||= new_socket
      end

      def new_socket
        socket = TCPSocket.new(@node.host, @node.pb_port)
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
        #TODO: Should we set the client ID here?
        # set_client_id @client.client_id
        socket
      end

      def reset_socket
        @socket.close if @socket && !@socket.closed?
        @socket = nil
      end

      UINTMAX = 0xffffffff
      QUORUMS = {
        "one" => UINTMAX - 1,
        "quorum" => UINTMAX - 2,
        "all" => UINTMAX - 3,
        "default" => UINTMAX - 4
      }.freeze

      def normalize_quorums(options={})
        options.dup.tap do |o|
          [:r, :pr, :w, :pw, :dw, :rw].each do |k|
            o[k] = normalize_quorum_value(o[k]) if o[k]
          end
        end
      end

      def normalize_quorum_value(q)
        QUORUMS[q.to_s] || q.to_i
      end
    end
  end
end
