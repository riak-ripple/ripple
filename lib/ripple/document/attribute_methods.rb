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
    module AttributeMethods
      extend ActiveSupport::Concern
      extend ActiveSupport::Autoload
      include ActiveModel::AttributeMethods

      autoload :Read
      autoload :Write
      autoload :Query

      included do
        include Read
        include Write
        include Query
      end

      module ClassMethods
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
        # included embedded documents.
        # @return [Hash] all document attributes, by key
        def attributes
          self.class.properties.values.inject({}) do |hash, prop|
            hash[prop.key] = attribute(prop.key)
            hash
          end.with_indifferent_access
        end

        # @private
        def initialize
          @attributes = {}.with_indifferent_access
          super
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
      end
    end
  end
end
