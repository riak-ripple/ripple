require 'active_support/concern'

module Ripple
  module AttributeMethods
    module Read
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix ""
      end

      def [](attr_name)
        attribute(attr_name)
      end

      private
      def attribute(attr_name)
        if @attributes.include?(attr_name)
          @attributes[attr_name]
        else
          nil
        end
      end
    end
  end
end
