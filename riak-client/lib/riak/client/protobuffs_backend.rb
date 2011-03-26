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
require 'socket'
require 'base64'
require 'digest/sha1'

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
        Thread.current[:riakpbc_socket] ||= TCPSocket.new(@client.host, @client.port)
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
