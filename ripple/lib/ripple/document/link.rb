require 'riak/link'

module Ripple
  module Document
    # A Link that is tied to a particular document and tag.
    # The key is fetched from the document lazily when needed.
    class Link < Riak::Link
      attr_reader :document
      private :document

      def initialize(document, tag)
        @document = document
        super(document.class.bucket_name, nil, tag)
      end

      def key
        document.key
      end

      def hash
        document.hash
      end
    end

    def to_link(tag)
      Link.new(self, tag)
    end
  end
end

