module Riak
  class Document < ::Riak::Object
    DOCUMENT_TYPES = [ /json$/i, /yaml$/i ].freeze
    
    def self.matches?(headers)
      DOCUMENT_TYPES.any? { |type| headers["content-type"].first =~ type }
    end
  end
end
