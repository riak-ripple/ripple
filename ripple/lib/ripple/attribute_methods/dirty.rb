require 'active_support/concern'
require 'active_model/dirty'

module Ripple
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      # @private
      def save(*args)
        if result = super
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
      def initialize(attrs={})
        super(attrs)
        changed_attributes.clear
      end

      # Like #changed? but also takes into account the entire embedded document hierarchy.
      # @return [Boolean] true if this document, or any of its embedded documents at any
      # level, have changed.
      def has_changes?
        changed? || self.class.embedded_associations.any? do |association|
          documents = send(association.name)
          documents = [documents] if association.one?
          documents = documents.reject { |d| d.nil? } # in case proxy is proxying nil
          documents.any? { |d| d.has_changes? }
        end
      end

      private
      def attribute=(attr_name, value)
        attribute_will_change!(attr_name) if @attributes[attr_name] != value
        super
      end
    end
  end
end
