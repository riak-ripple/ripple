require 'active_support/concern'
require 'active_model/dirty'

module Ripple
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      module ClassMethods
        # @private
        def instantiate(robject)
          super(robject).tap do |o|
            o.changed_attributes.clear
          end
        end
      end

      # @private
      def really_save(*args)
        if result = super
          @previously_changed = changes
          changed_attributes.clear
        end
        result
      end

      # @private
      def reload
        super.tap do
          changed_attributes.clear
        end
      end

      # @private
      def initialize(*args)
        super
        changed_attributes.clear
      end

      # Determines if the document has any chnages.
      # @return [Boolean] true if this document, or any of its embedded
      # documents at any level, have changed.
      def changed?
        super || self.class.embedded_associations.any? do |association|
          get_proxy(association).has_changed_documents?
        end
      end

      private
      def attribute=(attr_name, value)
        if self.class.properties.include?(attr_name.to_sym) && @attributes[attr_name] != value
          attribute_will_change!(attr_name)
        end
        super
      end
    end
  end
end
