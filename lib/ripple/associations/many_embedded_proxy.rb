require 'ripple/associations/proxy'
require 'ripple/associations/many'
require 'ripple/associations/embedded'

module Ripple
  module Associations
    class ManyEmbeddedProxy < Proxy
      include Many
      include Embedded

      def <<(docs)
        load_target
        docs = Array.wrap(docs)
        @reflection.verify_type!(docs, @owner)
        assign_references(docs)
        @target += docs
        self
      end

      def replace(docs)
        @reflection.verify_type!(docs, @owner)
        @_docs = docs.map { |doc| attrs = doc.respond_to?(:attributes_for_persistence) ? doc.attributes_for_persistence : doc }
        assign_references(docs)
        reset
        @_docs
      end

      protected
      def find_target
        (@_docs || []).map do |attrs|
          klass.instantiate(attrs).tap do |doc|
            assign_references(doc)
          end
        end
      end

    end
  end
end
