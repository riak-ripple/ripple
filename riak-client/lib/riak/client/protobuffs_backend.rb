require 'riak'
require 'socket'
require 'base64'
require 'digest/sha1'
require 'riak/util/translation'

module Riak
  class Client
    class ProtobuffsBackend
      include Util::Translation

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
      def initialize(client)
        @client = client
      end

      simple :ping,          :PingReq
      simple :get_client_id, :GetClientIdReq
      simple :server_info,   :GetServerInfoReq
      simple :list_buckets,  :ListBucketsReq

      private
      # Implemented by subclasses
      def decode_response
        raise NotImplementedError
      end

      def socket
        Thread.current[:riakpbc_socket] ||= new_socket
      end

      def new_socket
        socket = TCPSocket.new(@client.host, @client.pb_port)
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
        socket
      end

      def reset_socket
        socket.close
        Thread.current[:riakpbc_socket] = nil
      end

      UINTMAX = 0xffffffff
      QUORUMS = {
        "one" => UINTMAX - 1,
        "quorum" => UINTMAX - 2,
        "all" => UINTMAX - 3,
        "default" => UINTMAX - 4
      }.freeze

      def normalize_quorum_value(q)
        QUORUMS[q.to_s] || q.to_i
      end

      # This doesn't give us exactly the keygen that Riak uses, but close.
      def generate_key
        Base64.encode64(Digest::SHA1.digest(Socket.gethostname + Time.now.iso8601(3))).tr("+/","-_").sub(/=+\n$/,'')
      end
    end
  end
end
