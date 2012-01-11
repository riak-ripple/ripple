require 'ripple/translation'

module Ripple
  # Exception raised when the value assigned to a document property
  # cannot be coerced into the property's defined type.
  class PropertyTypeMismatch < StandardError
    include Translation
    def initialize(klass, value)
      super t("property_type_mismatch", :class => klass, :value => value.inspect)
    end
  end
end
