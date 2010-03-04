# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'ripple'

module Ripple
  module Document
    # Makes ActiveRecord-like attribute accessors based on your
    # {Document}'s properties.
    module AttributeMethods
      extend ActiveSupport::Concern
      extend ActiveSupport::Autoload
      include ActiveModel::AttributeMethods

      autoload :Read
      autoload :Write
      autoload :Query
      autoload :Dirty

      included do
        attr_accessor :key
        include Read
        include Write
        include Query
        include Dirty
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
          self.class.properties.values.inject({}) do |hash, prop|
            hash[prop.key] = attribute(prop.key)
            hash
          end.with_indifferent_access
        end

        # Mass assign the document's attributes.
        # @param [Hash] attrs the attributes to assign
        def attributes=(attrs)
          raise ArgumentError, t('attribute_hash') unless Hash === attrs
          attrs.each do |k,v|
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
            hash[prop.key] = prop.default if prop.default
            hash
          end.with_indifferent_access
        end
      end
    end
  end
end
