require 'ripple/associations/proxy'
require 'ripple/associations/one'
require 'ripple/associations/embedded'

module Ripple
  module Associations
    class OneEmbeddedProxy < Proxy
      include One
      include Embedded

      def replace(doc)
        @reflection.verify_type!(doc, @owner)
        @_doc = doc.respond_to?(:attributes_for_persistence) ? doc.attributes_for_persistence : doc
        assign_references(doc)

        if doc.is_a?(@reflection.klass)
          loaded
          @target = doc
        else
          reset
        end

        @_doc
      end

      protected
      def find_target
        return nil unless @_doc
        klass.instantiate(@_doc).tap do |doc|
          assign_references(doc)
        end
      end
    end
  end
end
