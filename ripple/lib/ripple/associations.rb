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
  # Adds associations via links and embedding to {Ripple::Document}
  # models. Examples:
  # 
  #   # Documents can contain embedded documents, and link to other standalone documents
  #   # via associations using the many and one class methods.
  #   class Person
  #     include Ripple::Document
  #     property :name, String
  #     many :addresses
  #     many :friends, :class_name => "Person"
  #     one :account
  #   end
  #    
  #   # Account and Address are embeddable documents
  #   class Account
  #     include Ripple::EmbeddedDocument
  #     property :paid_until, Time
  #     embedded_in :person # Adds "person" method to get parent document
  #   end
  #    
  #   class Address
  #     include Ripple::EmbeddedDocument
  #     property :street, String
  #     property :city, String
  #     property :state, String
  #     property :zip, String
  #   end
  #    
  #   person = Person.find("adamhunter")
  #   person.friends << Person.find("seancribbs") # Links to people/seancribbs with tag "friend"
  #   person.addresses << Address.new(:street => "100 Main Street") # Adds an embedded address
  #   person.account.paid_until = 3.months.from_now
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

        unless association.many?
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
          documents = instance_variable_get(association.ivar)
          # We must explicitly check #nil? (rather than just saying `if documents`)
          # because documents can be an association proxy that is proxying nil.
          # In this case ruby treats documents as true because it is not _really_ nil,
          # but #nil? will tell us if it is proxying nil.

          unless documents.nil?
            attrs[association.name] = documents.is_a?(Array) ? documents.map(&:attributes_for_persistence) : documents.attributes_for_persistence
          end
          attrs
        end
      end
    end
  end

  # The "reflection" for an association - metadata about how it is
  # configured.
  class Association
    include Ripple::Translation
    attr_reader :type, :name, :options

    # association options :using, :class_name, :class, :extend,
    # options that may be added :validate

    def initialize(type, name, options={})
      @type, @name, @options = type, name, options.to_options
    end

    # @return String The class name of the associated object(s)
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

    # @return [Class] The class of the associated object(s)
    def klass
      @klass ||= options[:class] || class_name.constantize
    end

    # @return [true,false] Is the cardinality of the association > 1
    def many?
      @type == :many
    end

    # @return [true,false] Is the cardinality of the association == 1
    def one?
      @type == :one
    end

    # @return [true,false] Is the associated class an EmbeddedDocument
    def embeddable?
      klass.embeddable?
    end

    # TODO: Polymorphic not supported
    # @return [true,false] Does the association support more than one associated class
    def polymorphic?
      false
    end

    # @return [true,false] Does the association use links
    def linked?
      using == :linked
    end

    # @return [String] the instance variable in the owner where the association will be stored
    def ivar
      "@_#{name}"
    end

    # @return [Class] the association proxy class
    def proxy_class
      @proxy_class ||= proxy_class_name.constantize
    end

    # @return [String] the class name of the association proxy
    def proxy_class_name
      klass_name = (many? ? 'Many' : 'One') + using.to_s.camelize + ('Polymorphic' if polymorphic?).to_s + 'Proxy'
      "Ripple::Associations::#{klass_name}"
    end

    # @return [Proc] a filter proc to be used with Enumerable#select for collecting links that belong to this association (only when #linked? is true)
    def link_filter
      linked? ? lambda {|link| link.tag == link_tag } : lambda {|_| false }
    end

    # @return [String,nil] when #linked? is true, the tag for outgoing links
    def link_tag
      linked? ? Array(link_spec).first.tag : nil
    end

    # @return [Riak::WalkSpec] when #linked? is true, a specification for which links to follow to retrieve the associated documents
    def link_spec
      # TODO: support transitive linked associations
      if linked?
        tag = name.to_s
        bucket = polymorphic? ? '_' : klass.bucket_name
        Riak::WalkSpec.new(:tag => tag, :bucket => bucket)
      else
        nil
      end
    end

    # @return [Symbol] which method is used for representing the association - currently only supports :embedded and :linked
    def using
      @using ||= options[:using] || (embeddable? ? :embedded : :linked)
    end

    # @raise [ArgumentError] if the value does not match the class of the association
    def verify_type!(value, owner)
      unless type_matches?(value)
        raise ArgumentError.new(t('invalid_association_value',
                                  :name => name,
                                  :owner => owner.inspect,
                                  :klass => polymorphic? ? "<polymorphic>" : klass.name,
                                  :value => value.inspect))
      end
    end

    # @private
    def type_matches?(value)
      case
      when polymorphic?
        one? || Array === value
      when many?
        Array === value && value.all? {|d| (embeddable? && Hash === d) || klass === d }
      when one?
        value.nil? || (embeddable? && Hash === value) || value.kind_of?(klass)
      end
    end
  end
end
