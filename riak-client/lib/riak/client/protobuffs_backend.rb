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

module Riak
  class Client
    class ProtobuffsBackend
      # Message Codes Enum
      ErrorResp           =  0
      PingReq             =  1
      PingResp            =  2
      GetClientIdReq      =  3
      GetClientIdResp     =  4
      SetClientIdReq      =  5
      SetClientIdResp     =  6
      GetServerInfoReq    =  7
      GetServerInfoResp   =  8
      GetReq              =  9
      GetResp             = 10
      PutReq              = 11
      PutResp             = 12
      DelReq              = 13
      DelResp             = 14
      ListBucketsReq      = 15
      ListBucketsResp     = 16
      ListKeysReq         = 17
      ListKeysResp        = 18
      GetBucketReq        = 19
      GetBucketResp       = 20
      SetBucketReq        = 21
      SetBucketResp       = 22
      MapRedReq           = 23
      MapRedResp          = 24

      def self.simple(method, code)
        class_eval "
          def #{method}                            # def ping
            socket.write([1,#{code}].pack('NC'))   #   socket.write([1,PingReq].pack('NC'))
            decode_response                        #   decode_response
          end"                                     # end
       end


    attr_accessor :client
    def initialize(client)
      @client = client
    end

    simple :ping,          PingReq
    simple :get_client_id, GetClientIdReq
    simple :server_info,   GetServerInfoReq
    simple :list_buckets,  ListBucketsReq

    private
    # Implemented by subclasses
    def decode_response
      raise NotImplementedError
    end

    def socket
      Thread.current[:riakpbc_socket] ||= TCPSocket.new(@client.host, @client.pb_port)
    end
  end
end
