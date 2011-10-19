require 'riak/robject'
require 'riak/link'
require 'riak/client/beefcake/messages'

module Riak
  class Client
    class BeefcakeProtobuffsBackend
      module ObjectMethods
        ENCODING = "Riak".respond_to?(:encoding)

        # Returns RpbPutReq
        def dump_object(robject, options={})
          pbuf = RpbPutReq.new(options.merge(:bucket => maybe_encode(robject.bucket.name)))
          pbuf.key = maybe_encode(robject.key) if robject.key # Put w/o key supported!
          pbuf.vclock = maybe_encode(Base64.decode64(robject.vclock)) if robject.vclock
          pbuf.content = RpbContent.new(:value => maybe_encode(robject.raw_data),
                                        :content_type => maybe_encode(robject.content_type),
                                        :links => robject.links.map {|l| encode_link(l) }.compact,
                                        :indexes => robject.indexes.map {|k,s| encode_index(k,s) }.flatten)

          pbuf.content.usermeta = robject.meta.map {|k,v| encode_meta(k,v)} if robject.meta.any?
          pbuf.content.vtag = maybe_encode(robject.etag) if robject.etag.present?
          if ENCODING # 1.9 support
            pbuf.content.charset = maybe_encode(robject.raw_data.encoding.name)
          end
          pbuf
        end

        # Returns RObject
        def load_object(pbuf, robject)
          return robject if pbuf.respond_to?(:unchanged) && pbuf.unchanged # Reloading
          robject.vclock = Base64.encode64(pbuf.vclock).chomp if pbuf.vclock
          robject.key = maybe_unescape(pbuf.key) if pbuf.respond_to?(:key) && pbuf.key # Put w/o key
          if pbuf.content.size > 1
            robject.conflict = true
            robject.siblings = pbuf.content.map do |c|
              sibling = RObject.new(robject.bucket, robject.key)
              sibling.vclock = robject.vclock
              load_content(c, sibling)
            end

            return robject.attempt_conflict_resolution
          else
            load_content(pbuf.content.first, robject)
          end
          robject
        end

        private
        def load_content(pbuf, robject)
          if ENCODING && pbuf.charset.present?
            pbuf.value.force_encoding(pbuf.charset) if Encoding.find(pbuf.charset)
          end
          robject.raw_data = pbuf.value
          robject.etag = pbuf.vtag if pbuf.vtag.present?
          robject.content_type = pbuf.content_type if pbuf.content_type.present?
          robject.links = pbuf.links.map(&method(:decode_link)) if pbuf.links.present?
          pbuf.usermeta.each {|pair| decode_meta(pair, robject.meta) } if pbuf.usermeta.present?
          if pbuf.indexes.present?
            robject.indexes.clear
            pbuf.indexes.each {|pair| decode_index(pair, robject.indexes) }
          end
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
          RpbLink.new(:bucket => maybe_encode(link.bucket.to_s),
                      :key => maybe_encode(link.key.to_s),
                      :tag => maybe_encode(link.tag.to_s))
        end

        def decode_meta(pbuf, hash)
          hash[pbuf.key] = pbuf.value
        end

        def encode_meta(key,value)
          return nil unless value.present?
          RpbPair.new(:key => maybe_encode(key.to_s),
                      :value => maybe_encode(value.to_s))
        end

        def decode_index(pbuf, hash)
          value = pbuf.key =~ /int$/ ? pbuf.value.to_i : pbuf.value
          hash[pbuf.key] << value
        end

        def encode_index(key, set)
          set.map do |v|
            RpbPair.new(:key => maybe_encode(key),
                        :value => maybe_encode(v.to_s))
          end
        end

        def maybe_encode(string)
          ENCODING ? string.dup.force_encoding('BINARY') : string
        end
      end

      include ObjectMethods
    end
  end
end
