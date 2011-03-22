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
require 'riak/client/pump'

module Riak
  class Client
    class BeefcakeProtobuffsBackend < ProtobuffsBackend
      def self.configured?
        begin
          require 'beefcake'
          require 'riak/client/beefcake/messages'
          require "riak/client/beefcake/object_methods"
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
        req = RpbSetClientIdReq.new(:client_id => value)
        write_protobuff(:SetClientIdReq, req)
        decode_response
      end

      def fetch_object(bucket, key, r=nil)
        req = RpbGetReq.new(:bucket => bucket, :key => key)
        req.r = normalize_quorum_value(r) if r
        write_protobuff(:GetReq, req)
        decode_response(RObject.new(client.bucket(bucket), key))
      end

      def reload_object(robject, r=nil)
        req = RpbGetReq.new(:bucket => bucket, :key => key)
        req.r = normalize_quorum_value(r) if r
        write_protobuff(:GetReq, req)
        decode_response(robject)
      end

      def store_object(robject, returnbody=false, w=nil, dw=nil)
        if robject.prevent_stale_writes
          other = fetch_object(robject.bucket, robject.key)
          raise Riak::FailedRequest(:pb, :not_stale, :stale, "stale write prevented") unless other.vclock == robject.vclock
        end
        req = dump_object(robject)
        req.w = normalize_quorum_value(w) if w
        req.dw = normalize_quorum_value(dw) if dw
        req.return_body = returnbody
        write_protobuff(:PutReq, req)
        decode_response(robject)
      end

      def delete_object(bucket, key, rw=nil)
        req = RpbDelReq.new(:bucket => bucket, :key => key)
        req.rw = normalize_quorum_value(rw) if rw
        write_protobuff(:DelReq, req)
        decode_response
      end

      def get_bucket_props(bucket)
        bucket = bucket.name if Bucket === bucket
        req = RpbGetBucketReq.new(:bucket => bucket)
        write_protobuff(:GetBucketReq, req)
        decode_response
      end

      def set_bucket_props(bucket, props)
        bucket = bucket.name if Bucket === bucket
        props = props.slice('n_val', 'allow_mult')
        req = RpbSetBucketReq.new(:bucket => bucket, :props => RpbBucketProps.new(props))
        write_protobuff(:SetBucketReq, req)
        decode_response
      end

      def list_keys(bucket, &block)
        bucket = bucket.name if Bucket === bucket
        req = RpbListKeysReq.new(:bucket => bucket)
        write_protobuff(:ListKeysReq, req)
        keys = []
        block = block_given? ? Pump.new(block).to_proc :  lambda {|kl| keys.concat kl }
        res = decode_response
        while res.respond_to?(:done) && !res.done
          block.call res.keys
          res = decode_response
        end
        block_given? || keys
      end

      def mapred(mr, &block)
        req = RpbMapRedReq.new(:request => mr.to_json, :content_type => "application/json")
        write_protobuff(:MapRedReq, req)
        results = Hash.new([])
        block = block_given? ? Pump.new(block).to_proc : lambda {|phase, data| results[phase].concat data }
        res = decode_response
        while !res.done
          block.call res.phase, JSON.parse(res.response)
          res = decode_response
        end
        block_given? || results
      end

      private
      def write_protobuff(code, message)
        encoded = message.encode
        socket.write([encoded.length+1, MESSAGE_CODES.index(code)].pack("NC"))
        socket.write(encoded)
      end

      def decode_response(*args)
        msglen, msgcode = socket.read(5).unpack("NC")
        if msglen == 1
          case MESSAGE_CODES[msgcode]
          when :PingResp, :SetClientIdResp, :PutResp, :DelResp, :SetBucketResp
            true
          when :ListBucketsResp, :ListKeysResp
            []
          when :GetResp
            raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
          else
            false
          end
        else
          message = socket.read(msglen-1)
          case MESSAGE_CODES[msgcode]
          when :ErrorResp
            res = RpbErrorResp.decode(message)
            raise Riak::ProtobufsFailedRequest.new(res.errcode, res.errmsg)
          when :GetClientIdResp
            res = RpbGetClientIdResp.decode(message)
            res.client_id
          when :GetServerInfoResp
            res = RpbGetServerInfoResp.decode(message)
            {:node => res.node, :server_version => res.server_version}
          when :GetResp, :PutResp
            res = RpbGetResp.decode(message)
            load_object(res, args.first)
          when :ListBucketsResp
            res = RpbListBucketsResp.decode(message)
            res.buckets
          when :ListKeysResp
            RpbListKeysResp.decode(message)
          when :GetBucketResp
            res = RpbGetBucketResp.decode(message)
            {'n_val' => res.props.n_val, 'allow_mult' => res.props.allow_mult}
          when :MapRedResp
            RpbMapRedResp.decode(message)
          end
        end
      rescue SocketError => e
        reset_socket
        raise Riak::ProtobufsFailedRequest.new(:server_error, e.message)
      end
    end
  end
end
