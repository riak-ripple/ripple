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
require 'riak/client/protobuffs_backend'

module Riak
  class Client
    attr_accessor :pb_port

    class JRubyProtobuffsBackend < ProtobuffsBackend
      def self.configured?
        begin
          require 'jruby'
          require File.expand_path("../../../../ext/jruby/riakclient.jar", __FILE__)
          true
        rescue LoadError, NameError
          false
        end
      end

      def set_client_id(id)
        value = case id
                when Integer
                  [id].pack("N")
                else
                  id.to_s
                end
        req = rPB::RpbSetClientIdReq.newBuilder.setClientId(byteString.copyFromUtf8(value.to_java_string)).build
        write_protobuff(SetClientIdReq, req)
        decode_response
      end

      private
      def write_protobuff(code, message)
        retryable {
          $stderr.puts "writing pbuf #{code}"
          socket.write([message.getSerializedSize.to_i, code].pack("NC"))
          message.writeTo(out)
        }
      end

      def decode_response
        $stderr.puts "decoding resp"
        msglen, msgcode = socket.read(5).unpack("NC")
        $stderr.puts "got len #{msglen} and code #{msgcode}"
        if msglen == 1
          case msgcode
          when PingResp, SetClientIdResp, PutResp, DelResp, SetBucketResp
            true
          when ListBucketsResp, ListKeysResp
            []
          when GetResp
            404 # Need to figure out what to do here... nil?
          else
            false
          end
        else
          message = socket.read(msglen-1)
          case msgcode
          when ErrorResp
            res = rPB::RpbErrorResp.parseFrom(message.to_java_bytes)
            raise FailedRequest.new(:pb, :ok, res.getErrcode, res.getErrmsg)
          when GetClientIdResp
            res = rPB::RpbGetClientIdResp.parseFrom(message.to_java_bytes)
            res.hasClientId ? res.getClientId.toStringUtf8.to_s.unpack("N").first : nil
          when GetServerInfoResp
            res = rPB::RpbGetServerInfoResp.parseFrom(message.to_java_bytes)
            {:node => res.hasNode && res.getNode.toStringUtf8.to_s,
              :server_version => res.hasServerVersion && res.getServerVersion.toStringUtf8.to_s}
          when GetResp
            res = rPB::RpbGetResp.parseFrom(message.to_java_bytes)
            { :vclock => res.hasVclock && res.getVclock,
              :values => [] }
            # res.getContentList.map {|content| decode_content(content)
          end
        end
      end

      def rPB
        unless @@RPB
          self.class.configured?
        end
        @@RPB
      end

      def byteString
        unless @@ByteString
          self.class.configured?
        end
        @@ByteString
      end

      def retryable
        retries = 3
        begin
          yield
        rescue Errno::EPIPE => e
          Thread.current[:riakpbc_socket] = nil
          Thread.current[:riakpbc_out_stream] = nil
          if retries > 0
            $stderr.puts "retrying!"
            retries -= 1
            retry
          else
            raise e
          end
        end
      end
      # def decode_content(c)
      #   {}.tap do |h|
      #     h[:content_type]        = c.getContentType.toStringUtf8     if c.hasContentType
      #     h[:charset]             = c.getCharset.toStringUtf8         if c.hasCharset
      #     h[:encoding]            = c.getContentEncoding.toStringUtf8 if c.hasContentEncoding
      #     h[:etag]                = c.getVtag.toStringUtf8            if c.hasVtag
      #     h[:last_modified]       = c.getLastMod                      if c.hasLastMod
      #     h[:last_modified_usecs] = c.getLastModUsecs                 if c.hasLastModUsecs
      #     h[:links]               = c.getLinksList.map do |l|
      #     end
      #   end
      # end

      def out
        Thread.current[:riakpbc_out_stream] ||= com.google.protobuf.CodedOutputStream.newInstance(socket.to_java.get_out_stream)
      end

      # def in
      #   Thread.current[:riakpbc_in_stream] ||= com.google.protobuf.CodedInputStream.newInstance(socket.getInStream)
      # end
    end
  end
end
