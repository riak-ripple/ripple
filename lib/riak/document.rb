require 'riak'

module Riak
  # Represents hash-like documents (JSON, YAML). Documents will be automatically
  # serialized into the appropriate format when sent in requests and deserialized
  # from responses.
  class Document < RObject
    DOCUMENT_TYPES = [ /json$/i, /yaml$/i ].freeze

    def self.matches?(headers)
      DOCUMENT_TYPES.any? { |type| headers["content-type"].first =~ type }
    end

    def serialize(data)
      case @content_type
      when /json$/i
        data.to_json
      when /yaml$/i
        YAML.dump(data)
      else
        data
      end
    end

    def deserialize(data)
      case @content_type
      when /json$/i
        JSON.parse(data)
      when /yaml$/i
        YAML.load(data)
      else
        data
      end
    end
  end
end
