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

      private
      def attribute=(attr_name, value)
        attribute_will_change!(attr_name) if @attributes[attr_name] != value
        super
      end
    end
  end
end
