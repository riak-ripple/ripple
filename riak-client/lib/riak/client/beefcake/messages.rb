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
require 'riak/link'
require 'beefcake'

module Riak
  class Client
    # @private
    class BeefcakeProtobuffsBackend
      # Embedded messages
      class RpbPair
        include Beefcake::Message
        required :key,   :bytes, 1
        optional :value, :bytes, 2
      end

      class RpbBucketProps
        include Beefcake::Message
        optional :n_val,      :uint32, 1
        optional :allow_mult, :bool,   2
      end

      class RpbLink
        include Beefcake::Message
        optional :bucket, :bytes, 1
        optional :key,    :bytes, 2
        optional :tag,    :bytes, 3
      end

      class RpbContent
        include Beefcake::Message
        required :value,            :bytes,  1
        optional :content_type,     :bytes,  2
        optional :charset,          :bytes,  3
        optional :content_encoding, :bytes,  4
        optional :vtag,             :bytes,  5
        repeated :links,            RpbLink, 6
        optional :last_mod,         :uint32, 7
        optional :last_mod_usecs,   :uint32, 8
        repeated :usermeta,         RpbPair, 9
      end

      # Primary messages
      class RpbErrorResp
        include Beefcake::Message
        required :errmsg,  :bytes,  1
        required :errcode, :uint32, 2
      end

      class RpbGetClientIdResp
        include Beefcake::Message
        required :client_id, :bytes, 1
      end

      class RpbSetClientIdReq
        include Beefcake::Message
        required :client_id, :bytes, 1
      end

      class RpbGetServerInfoResp
        include Beefcake::Message
        optional :node,           :bytes, 1
        optional :server_version, :bytes, 2
      end

      class RpbGetReq
        include Beefcake::Message
        required :bucket, :bytes,  1
        required :key,    :bytes,  2
        optional :r,      :uint32, 3
      end

      class RpbGetResp
        include Beefcake::Message
        repeated :content, RpbContent, 1
        optional :vclock,  :bytes,  2
      end

      class RpbPutReq
        include Beefcake::Message
        required :bucket,      :bytes,  1
        required :key,         :bytes,  2
        optional :vclock,      :bytes,  3
        required :content,     RpbContent, 4
        optional :w,           :uint32, 5
        optional :dw,          :uint32, 6
        optional :return_body, :bool,   7
      end

      # Optional since it has the same structure as GetResp
      # class RpbPutResp
      #   include Beefcake::Message
      #   repeated :content, RpbContent, 1
      #   optional :vclock,  :bytes,  2
      # end

      class RpbDelReq
        include Beefcake::Message
        required :bucket, :bytes,  1
        required :key,    :bytes,  2
        optional :rw,     :uint32, 3
      end

      class RpbListBucketsResp
        include Beefcake::Message
        repeated :buckets, :bytes, 1
      end

      class RpbListKeysReq
        include Beefcake::Message
        required :bucket, :bytes, 1
      end

      class RpbListKeysResp
        include Beefcake::Message
        repeated :keys, :bytes, 1
        optional :done, :bool,  2
      end

      class RpbGetBucketReq
        include Beefcake::Message
        required :bucket, :bytes, 1
      end

      class RpbGetBucketResp
        include Beefcake::Message
        required :props, RpbBucketProps, 1
      end

      class RpbSetBucketReq
        include Beefcake::Message
        required :bucket, :bytes,         1
        required :props,  RpbBucketProps, 2
      end

      class RpbMapRedReq
        include Beefcake::Message
        required :request,      :bytes, 1
        required :content_type, :bytes, 2
      end

      class RpbMapRedResp
        include Beefcake::Message
        optional :phase,    :uint32, 1
        optional :response, :bytes,  2
        optional :done,     :bool,   3
      end
    end
  end
end
