module Riak
  # Represents hash-like documents (JSON, YAML)
  class Document < RObject
    DOCUMENT_TYPES = [ /json$/i, /yaml$/i ].freeze

    def self.matches?(headers)
      DOCUMENT_TYPES.any? { |type| headers["content-type"].first =~ type }
    end
  end
end
