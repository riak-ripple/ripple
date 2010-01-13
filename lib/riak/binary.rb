module Riak
  class Binary < ::Riak::Object
    BINARY_TYPES = [ /^application/i, /^multipart/i, /^image/i, /^audio/i, /^video/i ].freeze
    
    def self.matches?(headers)
      BINARY_TYPES.any? {|type| headers['content-type'].first =~ type } 
    end
  end
end
