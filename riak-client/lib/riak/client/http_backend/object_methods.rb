require 'uri'
require 'set'
require 'time'
require 'riak/client/http_backend'
require 'riak/robject'
require 'riak/link'
require 'riak/util/multipart'

module Riak
  class Client
    class HTTPBackend
      # Methods for assisting with the handling of {RObject}s present
      # in HTTP requests and responses.
      module ObjectMethods
        # HTTP header hash that will be sent along when reloading the object
        # @return [Hash] hash of HTTP headers
        def reload_headers(robject)
          {}.tap do |h|
            h['If-None-Match'] = robject.etag if robject.etag.present?
            h['If-Modified-Since'] = robject.last_modified.httpdate if robject.last_modified.present?
          end
        end

        # HTTP header hash that will be sent along when storing the object
        # @return [Hash] hash of HTTP Headers
        def store_headers(robject)
          {}.tap do |hash|
            hash["Content-Type"] = robject.content_type
            hash["X-Riak-Vclock"] = robject.vclock if robject.vclock
            if robject.prevent_stale_writes && robject.etag.present?
              hash["If-Match"] = robject.etag
            elsif robject.prevent_stale_writes
              hash["If-None-Match"] = "*"
            end
            unless robject.links.blank?
              hash["Link"] = robject.links.reject {|l| l.rel == "up" }.map {|l| l.to_s(new_scheme?) }.join(", ")
            end
            unless robject.meta.blank?
              robject.meta.each do |k,v|
                hash["X-Riak-Meta-#{k}"] = v.to_s
              end
            end
            unless robject.indexes.blank?
              robject.indexes.each do |k,v|
                hash["X-Riak-Index-#{k}"] = v.to_a.sort.map {|i| i.to_s }.join(", ")
              end
            end
          end
        end

        # Load object data from an HTTP response
        # @param [Hash] response a response from {Riak::Client::HTTPBackend}
        def load_object(robject, response)
          extract_header(robject, response, "location", :key) {|v| URI.unescape(v.match(%r{.*/(.*?)(\?.*)?$})[1]) }
          extract_header(robject, response, "content-type", :content_type)
          extract_header(robject, response, "x-riak-vclock", :vclock)
          extract_header(robject, response, "link", :links) {|v| Set.new(Link.parse(v)) }
          extract_header(robject, response, "etag", :etag)
          extract_header(robject, response, "last-modified", :last_modified) {|v| Time.httpdate(v) }
          robject.meta = response[:headers].inject({}) do |h,(k,v)|
            if k =~ /x-riak-meta-(.*)/i
              h[$1] = v
            end
            h
          end
          robject.indexes = response[:headers].inject(Hash.new {|h,k| h[k] = Set.new }) do |h,(k,v)|
            if k =~ /x-riak-index-((?:.*)_(?:int|bin))$/i
              key = $1
              h[key].merge Array(v).map {|vals| vals.split(/,\s*/).map {|i| key =~ /int$/ ? i.to_i : i } }.flatten
            end
            h
          end
          robject.conflict = (response[:code] && response[:code].to_i == 300 && robject.content_type =~ /multipart\/mixed/)
          robject.siblings = robject.conflict? ? extract_siblings(robject, response[:body]) : nil
          robject.raw_data = response[:body] if response[:body].present? && !robject.conflict?

          robject.conflict? ? robject.attempt_conflict_resolution : robject
        end

        private
        def extract_header(robject, response, name, attribute=nil, &block)
          extract_if_present(robject, response[:headers], name, attribute) do |value|
            block ? block.call(value[0]) : value[0]
          end
        end

        def extract_if_present(robject, hash, key, attribute=nil)
          if hash[key].present?
            attribute ||= key
            value = block_given? ? yield(hash[key]) : hash[key]
            robject.send("#{attribute}=", value)
          end
        end

        def extract_siblings(robject, data)
          Util::Multipart.parse(data, Util::Multipart.extract_boundary(robject.content_type)).map do |part|
            RObject.new(robject.bucket, robject.key) do |sibling|
              load_object(sibling, part)
              sibling.vclock = robject.vclock
            end
          end
        end
      end
    end
  end
end
