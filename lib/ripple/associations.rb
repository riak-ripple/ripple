require 'active_support/concern'
require 'active_support/dependencies'
require 'riak/walk_spec'
require 'ripple/translation'
require 'ripple/associations/proxy'
require 'ripple/associations/instantiators'
require 'ripple/associations/linked'
require 'ripple/associations/embedded'
require 'ripple/associations/many'
require 'ripple/associations/one'
require 'ripple/associations/linked'
require 'ripple/associations/one_embedded_proxy'
require 'ripple/associations/many_embedded_proxy'
require 'ripple/associations/one_linked_proxy'
require 'ripple/associations/many_linked_proxy'
require 'ripple/associations/many_stored_key_proxy'
require 'ripple/associations/one_key_proxy'
require 'ripple/associations/one_stored_key_proxy'
require 'ripple/associations/many_reference_proxy'

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

    module ClassMethods
      include Translation
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
        associations.values.select(&:embedded?)
      end

      # Associations of linked documents
      def linked_associations
        associations.values.select(&:linked?)
      end

      # Associations of stored_key documents
      def stored_key_associations
        associations.values.select(&:stored_key?)
      end

      # Creates a singular association
      def one(name, options={})
        configure_for_key_correspondence if options[:using] === :key
        create_association(:one, name, options)
      end

      # Creates a plural association
      def many(name, options={})
        raise ArgumentError, t('many_key_association') if options[:using] === :key
        create_association(:many, name, options)
      end

      def configure_for_key_correspondence
        include Ripple::Associations::KeyDelegator
      end

      private
      def create_association(type, name, options={})
        association = associations[name] = Association.new(type, name, options)
        association.validate!(self)
        association.setup_on(self)

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


    # @private
    def get_proxy(association)
      unless proxy = instance_variable_get(association.ivar)
        proxy = association.proxy_class.new(self, association)
        instance_variable_set(association.ivar, proxy)
      end
      proxy
    end

    # @private
    def reset_associations
      self.class.associations.each do |name, assoc_object|
        send(name).reset
      end
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

    def propagate_callbacks_to_embedded_associations(name, kind)
      self.class.embedded_associations.each do |association|
        documents = instance_variable_get(association.ivar)
        # We must explicitly check #nil? (rather than just saying `if documents`)
        # because documents can be an association proxy that is proxying nil.
        # In this case ruby treats documents as true because it is not _really_ nil,
        # but #nil? will tell us if it is proxying nil.
        next if documents.nil?

        Array(documents).each do |doc|
          doc.send("_#{name}_callbacks").each do |callback|
            next unless callback.kind == kind
            doc.send(callback.filter)
          end
        end
      end
    end

    # Propagates callbacks (save/create/update/destroy) to embedded associated documents.
    # This is necessary so that when a parent is saved, the embedded child's before_save
    # hooks are run as well.
    # @private
    def run_callbacks(name, *args, &block)
      # validation is already propagated to embedded documents via the
      # AssociatedValidator.  We don't need to duplicate the propagation here.
      return super if name == :validation

      propagate_callbacks_to_embedded_associations(name, :before)
      return_value = super
      propagate_callbacks_to_embedded_associations(name, :after)
      return_value
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

    def validate!(owner)
      # TODO: Refactor this into an association subclass. See also GH #284
      if @options[:using] == :stored_key
        single_name = ActiveSupport::Inflector.singularize(@name.to_s)
        prop_name = "#{single_name}_key"
        prop_name << "s" if many?
        raise ArgumentError, t('stored_key_requires_property', :name => prop_name) unless owner.properties.include?(prop_name)
      end
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
      @klass ||= discover_class
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
    def embedded?
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

    # @return [true,false] Does the association use stored_key
    def stored_key?
      using == :stored_key
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

    def bucket_name
      polymorphic? ? '_' : klass.bucket_name
    end

    # @return [Riak::WalkSpec] when #linked? is true, a specification for which links to follow to retrieve the associated documents
    def link_spec
      # TODO: support transitive linked associations
      if linked?
        tag = name.to_s
        Riak::WalkSpec.new(:tag => tag, :bucket => bucket_name)
      else
        nil
      end
    end

    # @return [Symbol] which method is used for representing the association - currently only supports :embedded and :linked
    def using
      @using ||= options[:using] || (embedded? ? :embedded : :linked)
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
        one? || value.is_a?(Array)
      when many?
        value.is_a?(Array) && value.all? {|d| (embedded? && d.is_a?(Hash)) || d.kind_of?(klass) }
      when one?
        value.nil? || (embedded? && value.is_a?(Hash)) || value.kind_of?(klass)
      end
    end

    def uses_search?
      (options[:using] == :reference)
    end

    def setup_on(model)
      @model = model
      define_callbacks_on(model)
      if uses_search?
        klass.before_save do |o|
          unless o.class.bucket.is_indexed?
            o.class.bucket.enable_index!
          end
        end
      end
    end

    def define_callbacks_on(klass)
      _association = self

      klass.before_save do
        if _association.linked? && !@_in_save_loaded_documents_callback
          @_in_save_loaded_documents_callback = true

          begin
            send(_association.name).loaded_documents.each do |document|
              document.save if document.new? || document.changed?
            end
          ensure
            remove_instance_variable(:@_in_save_loaded_documents_callback)
          end
        end
      end
    end

    private
    def discover_class
      options[:class] || (@model && find_class(@model, class_name)) || class_name.constantize
    end

    def find_class(scope, class_name)
      return nil if class_name.include?("::")
      class_sym = class_name.to_sym
      parent_scope = scope.parents.unshift(scope).find {|s| s.const_defined?(class_sym, false) }
      parent_scope.const_get(class_sym) if parent_scope
    end
  end
end
