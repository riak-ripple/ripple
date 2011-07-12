require 'ripple/translation'
require 'active_support/concern'
require 'active_model/attribute_methods'
require 'active_model/mass_assignment_security'
require 'ripple/attribute_methods/read'
require 'ripple/attribute_methods/write'
require 'ripple/attribute_methods/query'
require 'ripple/attribute_methods/dirty'

module Ripple
  # Makes ActiveRecord-like attribute accessors based on your
  # {Document}'s properties.
  module AttributeMethods
    include Translation
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      include Read
      include Write
      include Query
      include Dirty
      include ActiveModel::MassAssignmentSecurity
      
      attr_protected :key
    end

    module ClassMethods
      # @private
      def property(key, type, options={})
        undefine_attribute_methods
        super
      end

      # Generates all the attribute-related methods for properties defined
      # on the document, including accessors, mutators and query methods.
      def define_attribute_methods
        super(properties.keys)
      end
    end

    module InstanceMethods
      # A copy of the values of all attributes in the Document. The result
      # is not memoized, so use sparingly.  This does not include associated objects,
      # nor embedded documents.
      # @return [Hash] all document attributes, by key
      def attributes
        raw_attributes.reject { |k, v| !respond_to?(k) }
      end

      def raw_attributes
        self.class.properties.values.inject(@attributes.with_indifferent_access) do |hash, prop|
          hash[prop.key] = attribute(prop.key)
          hash
        end
      end

      # Mass assign the document's attributes.
      # @param [Hash] attrs the attributes to assign
      def attributes=(attrs)
        raise ArgumentError, t('attribute_hash') unless Hash === attrs
        sanitize_for_mass_assignment(attrs).each do |k,v|
          if respond_to?("#{k}=")
            __send__("#{k}=",v)
          else
            raise ArgumentError, t('undefined_property', :prop => k, :class => self.class.name)
          end
        end
      end

      # @private
      def raw_attributes=(attrs)
        raise ArgumentError, t('attribute_hash') unless Hash === attrs
        attrs.each do |k,v|
          next if k.to_sym == :key
          if respond_to?("#{k}=")
            __send__("#{k}=",v)
          else
            __send__(:attribute=,k,v)
          end
        end
      end

      # @private
      def initialize(attrs={})
        super()
        @attributes = attributes_from_property_defaults
        self.attributes = attrs
        yield self if block_given?
      end

      # @private
      def method_missing(method, *args, &block)
        self.class.define_attribute_methods
        super
      end

      # @private
      def respond_to?(*args)
        self.class.define_attribute_methods
        super
      end

      protected
      # @private
      def attribute_method?(attr_name)
        self.class.properties.include?(attr_name)
      end

      def attributes_from_property_defaults
        self.class.properties.values.inject({}) do |hash, prop|
          hash[prop.key] = prop.default unless prop.default.nil?
          hash
        end.with_indifferent_access
      end
    end
  end
end
