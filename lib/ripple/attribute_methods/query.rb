require 'active_support/concern'

module Ripple
  module AttributeMethods
    module Query
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix "?"
      end

      private
      # Based on code from ActiveRecord
      def attribute?(attr_name)
        unless value = attribute(attr_name)
          false
        else
          prop = self.class.properties[attr_name]
          if prop.nil?
            if Numeric === value || value !~ /[^0-9]/
              !value.to_i.zero?
            else
              Boolean.ripple_cast(value) || value.present?
            end
          elsif prop.type <= Numeric
            !value.zero?
          else
            value.present?
          end
        end
      end
    end
  end
end
