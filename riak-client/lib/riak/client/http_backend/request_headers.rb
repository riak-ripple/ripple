
require 'riak/util/headers'

module Riak
  class Client
    class HTTPBackend
      # @private
      class RequestHeaders < Riak::Util::Headers
        alias each each_capitalized

        def initialize(hash)
          initialize_http_header(hash)
        end

        def to_a
          [].tap do |arr|
            each_capitalized do |k,v|
              arr << "#{k}: #{v}"
            end
          end
        end

        def to_hash
          {}.tap do |hash|
            each_capitalized do |k,v|
              hash[k] ||= []
              hash[k] << v
            end
          end
        end
      end
    end
  end
end
