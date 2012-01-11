require 'active_support/concern'

module Ripple
  module AttributeMethods
    module Write
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix "="
      end

      def []=(attr_name, value)
        __send__(:attribute=, attr_name, value)
      end

      private
      def attribute=(attr_name, value)
        if prop = self.class.properties[attr_name]
          value = prop.type_cast(value)
        end
        @attributes[attr_name] = value
      end
    end
  end
end
