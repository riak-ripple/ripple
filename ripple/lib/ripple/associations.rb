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
  module Associations
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :Proxy
    autoload :One
    autoload :Many
    autoload :Embedded
    autoload :Linked
    autoload :Instantiators
    autoload :OneEmbeddedProxy
    autoload :ManyEmbeddedProxy
    autoload :OneLinkedProxy
    autoload :ManyLinkedProxy

    module ClassMethods
      # @private
      def inherited(subclass)
        super
        subclass.associations.merge!(associations)
      end

      # Associations defined on the document
      def associations
        @associations ||= {}.with_indifferent_access
      end

      # Associations of embedded documents
      def embedded_associations
        associations.values.select(&:embeddable?)
      end

      # Creates a singular association
      def one(name, options={})
        create_association(:one, name, options)
      end

      # Creates a plural association
      def many(name, options={})
        create_association(:many, name, options)
      end

      private
      def create_association(type, name, options={})
        association = associations[name] = Association.new(type, name, options)

        define_method(name) do
          get_proxy(association)
        end

        define_method("#{name}=") do |value|
          get_proxy(association).replace(value)
          value
        end

        if association.one?
          define_method("#{name}?") do
            get_proxy(association).present?
          end
        end
      end
    end

    module InstanceMethods
      # @private
      def get_proxy(association)
        unless proxy = instance_variable_get(association.ivar)
          proxy = association.proxy_class.new(self, association)
          instance_variable_set(association.ivar, proxy)
        end
        proxy
      end

      # Adds embedded documents to the attributes
      # @private
      def attributes_for_persistence
        self.class.embedded_associations.inject(super) do |attrs, association|
          if documents = instance_variable_get(association.ivar)
            attrs[association.name] = documents.is_a?(Array) ? documents.map(&:attributes_for_persistence) : documents.attributes_for_persistence
          end
          attrs
        end
      end
    end
  end

  class Association
    attr_reader :type, :name, :options

    # association options :using, :class_name, :class, :extend,
    # options that may be added :validate

    def initialize(type, name, options={})
      @type, @name, @options = type, name, options.to_options
    end

    def class_name
      @class_name ||= case
                      when @options[:class_name]
                        @options[:class_name]
                      when @options[:class]
                        @options[:class].to_s
                      when many?
                        @name.to_s.classify
                      else
                        @name.to_s.camelize
                      end
    end

    def klass
      @klass ||= options[:class] || class_name.constantize
    end

    def many?
      @type == :many
    end

    def one?
      @type == :one
    end

    def embeddable?
      klass.embeddable?
    end

    def polymorphic?
      false
    end

    def ivar
      "@_#{name}"
    end

    def proxy_class
      @proxy_class ||= proxy_class_name.constantize
    end

    def proxy_class_name
      @using   ||= options[:using] || (embeddable? ? :embedded : :linked)
      klass_name = (many? ? 'Many' : 'One') + @using.to_s.camelize + ('Polymorphic' if polymorphic?).to_s + 'Proxy'
      "Ripple::Associations::#{klass_name}"
    end
  end
end
