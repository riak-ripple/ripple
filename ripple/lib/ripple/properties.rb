require 'ripple/core_ext/casting'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/indifferent_access'

module Ripple
  # Adds the ability to declare properties on your Ripple::Document class.
  # Properties will automatically generate accessor (get/set/query) methods and
  # handle type-casting between your Ruby type and JSON-compatible types.
  module Properties
    # @private
    def inherited(subclass)
      super
      subclass.properties.merge!(properties)
    end

    # @return [Hash] the properties defined on the document
    def properties
      @properties ||= {}.with_indifferent_access
    end

    def property(key, type, options={})
      prop = Property.new(key, type, options)
      properties[prop.key] = prop
    end
  end

  # Encapsulates a single property on your Ripple::Document class.
  class Property
    # @return [Symbol] the key of this property in the Document
    attr_reader :key
    # @return [Class] the Ruby type of property.
    attr_reader :type
    # @return [Hash] configuration options
    attr_reader :options

    # Create a new document property.
    # @param [String, Symbol] key the key of the property
    # @param [Class] type the Ruby type of the property. Use {Boolean} for true or false types.
    # @param [Hash] options configuration options
    # @option options [Object, Proc] :default (nil) a default value
    #   for the property, or a lambda to evaluate when providing the default.
    def initialize(key, type, options={})
      @options = options.to_options
      @key = key.to_sym
      @type = type
    end

    # @return [Object] The default value for this property if defined, or nil.
    def default
      default = options[:default]
      default = default.dup if default.duplicable?

      return nil if default.nil?
      type_cast(default.respond_to?(:call) ? default.call : default)
    end

    # @return [Hash] options appropriate for the validates class method
    def validation_options
      @options.dup.except(:default)
    end
    
    # Attempt to coerce the passed value into this property's type
    # @param [Object] value the value to coerce
    # @return [Object] the value coerced into this property's type
    # @raise [PropertyTypeMismatch] if the value cannot be coerced into the property's type
    def type_cast(value)
      if @type.respond_to?(:ripple_cast)
        @type.ripple_cast(value)
      else
        value
      end
    end
  end
end
