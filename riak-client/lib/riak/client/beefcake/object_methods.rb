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
  class Client
    class BeefcakeProtobuffsBackend
      module ObjectMethods
        # Returns RpbPutReq
        def dump_object(robject)
          pbuf = RpbPutReq.new(:bucket => robject.bucket.name)
          pbuf.key = robject.key || generate_key
          pbuf.vclock = Base64.decode64(robject.vclock) if robject.vclock
          pbuf.content = RpbContent.new(:value => robject.raw_data,
                                        :content_type => robject.content_type,
                                        :links => robject.links.map {|l| encode_link(l) }.compact)

          pbuf.content.usermeta = robject.meta.map {|k,v| encode_meta(k,v)} if robject.meta.any?
          pbuf.content.vtag = robject.etag if robject.etag.present?
          if robject.raw_data.respond_to?(:encoding) # 1.9 support
            pbuf.content.charset = robject.raw_data.encoding.name
          end
          pbuf
        end

        # Returns RObject
        def load_object(pbuf, robject)
          robject.vclock = Base64.encode64(pbuf.vclock).chomp if pbuf.vclock
          if pbuf.content.size > 1
            robject.conflict = true
            robject.siblings = pbuf.content.map do |c|
              sibling = RObject.new(robject.bucket, robject.key)
              sibling.vclock = robject.vclock
              load_content(c, sibling)
            end
          else
            load_content(pbuf.content.first, robject)
          end
          robject
        end

        private
        def load_content(pbuf, robject)
          if pbuf.value.respond_to?(:force_encoding) && pbuf.charset.present?
            pbuf.value.force_encoding(pbuf.charset) if Encoding.find(pbuf.charset)
          end
          robject.raw_data = pbuf.value
          robject.etag = pbuf.vtag if pbuf.vtag.present?
          robject.content_type = pbuf.content_type if pbuf.content_type.present?
          robject.links = pbuf.links.map(&method(:decode_link)) if pbuf.links.present?
          pbuf.usermeta.each {|pair| decode_meta(pair, robject.meta) } if pbuf.usermeta.present?
          if pbuf.last_mod.present?
            robject.last_modified = Time.at(pbuf.last_mod)
            robject.last_modified += pbuf.last_mod_usecs / 1000000 if pbuf.last_mod_usecs.present?
          end
          robject
        end

        def decode_link(pbuf)
          Riak::Link.new(pbuf.bucket, pbuf.key, pbuf.tag)
        end

        def encode_link(link)
          return nil unless link.key.present?
          RpbLink.new(:bucket => link.bucket.to_s, :key => link.key.to_s, :tag => link.tag.to_s)
        end

        def decode_meta(pbuf, hash)
          hash[pbuf.key] = pbuf.value
        end

        def encode_meta(key,value)
          return nil unless value.present?
          RpbPair.new(:key.to_s, :value => value.to_s)
        end
      end

      include ObjectMethods
    end
  end
end
