require 'ripple'
module Ripple
  module NestedAttributes #:nodoc:
    extend ActiveSupport::Concern

    UNASSIGNABLE_KEYS = %w{ _destroy }
    TRUE_VALUES = [ true, "true", 1, "1", "yes", "ok", "y" ]

    included do
      class_inheritable_accessor :nested_attributes_options, :instance_writer => false
      self.nested_attributes_options = {}
    end
    
    # = Nested Attributes
    #
    # This is similar to the `accepts_nested_attributes` functionality
    # as found in AR.  This allows the use update attributes and create
    # new child records through the parent.  It also allows the use of
    # the `fields_for` form view helper, using a presenter pattern.
    #
    # To enable in the model, call the class method, using the same
    # relationship as defined in the `one` or `many`.
    #
    #   class Shipment
    #     include Ripple::Document
    #     one :box
    #     many :addresses
    #     accepts_nested_attributes_for :box, :addresses
    #   end
    #
    # == One
    #
    # Given this model:
    #
    #   class Shipment
    #     include Ripple::Document
    #     one :box
    #     accepts_nested_attributes_for :box
    #   end
    #
    # This allows creating a box child during creation:
    #
    #   shipment = Shipment.create(:box_attributes => { :shape => 'square' })
    #   shipment.box.shape # => 'square'
    #
    # This also allows updating box attributes:
    #
    #   shipment.update_attributes(:box_attributes => { :key => 'xxx', :shape => 'triangle' })
    #   shipment.box.shape # => 'triangle'
    #
    # == Many
    #
    # Given this model
    #
    #   class Manifest
    #     include Ripple::Document
    #     many :shipments
    #     accepts_nested_attributes_for :shipments
    #   end
    #
    # This allows creating several shipments during manifest creation:
    #
    #   manifest = Manifest.create(:shipments_attributes => [ { :reference => "foo1" }, { :reference => "foo2" } ])
    #   manifest.shipments.size # => 2
    #   manifest.shipments.first.reference # => foo1
    #   manifest.shipments.second.reference # => foo2
    #
    # And updating shipment attributes:
    #
    #   manifest.update_attributes(:shipment_attributes => [ { :key => 'xxx', :reference => 'updated foo1' },
    #                                                        { :key => 'yyy', :reference => 'updated foo2' } ])
    #   manifest.shipments.first.reference # => updated foo1
    #   manifest.shipments.second.reference # => updated foo2
    # 
    # NOTE: On many embedded, then entire collection of embedded documents is replaced, as there
    # is no key to specifically update.
    #
    # Given
    #
    #   class Manifest
    #     include Ripple::Documnet
    #     many :signatures
    #     accepts_nested_attributes_for :signatures
    #   end
    #
    #   class Signature
    #     include Ripple::EmbeddedDocument
    #     property :esignature, String
    #   end
    #
    # The assigning of attributes replaces existing:
    #   
    #   manifest = Manifest.create(:signature_attributes => [ { :esig => 'a00001' }, { :esig => 'b00001' } ]
    #   manifest.signatures # => [<Signature esig="a00001">, <Signature esig="b00001">]
    #
    #   manifest.signature_attributes = [ { :esig => 'c00001' } ]
    #   manifest.signatures # => [<Signature esig="c00001">]
    #     
    module ClassMethods
    
      def accepts_nested_attributes_for(*attr_names)
        options = { :allow_destroy => false }
        options.update(attr_names.extract_options!)
        
        attr_names.each do |association_name|
          if association = self.associations[association_name]
            nested_attributes_options[association_name.to_sym] = options
         
            class_eval %{
              def #{association_name}_attributes=(attributes)
                assign_nested_attributes_for_#{association.type}_association(:#{association_name}, attributes)
              end

              before_save :autosave_nested_attributes_for_#{association_name}
              before_save :destroy_marked_for_destruction

              private

              def autosave_nested_attributes_for_#{association_name}
                save_nested_attributes_for_#{association.type}_association(:#{association_name}) if self.autosave[:#{association_name}]
              end
            }, __FILE__, __LINE__
          else
            raise ArgumentError, "Association #{association_name} not found!"
          end
        end        
      end
    end

    module InstanceMethods

      protected

      def autosave
        @autosave_nested_attributes_for ||= {}
      end

      def marked_for_destruction
        @marked_for_destruction ||= {}
      end

      private
      
      def save_nested_attributes_for_one_association(association_name)
        send(association_name).save
      end

      def save_nested_attributes_for_many_association(association_name)
        send(association_name).map(&:save)
      end

      def destroy_marked_for_destruction
        self.marked_for_destruction.each_pair do |association_name, resources|
          resources.map(&:destroy)
          send(association_name).reload
        end
      end

      def destroy_nested_many_association(association_name)
        send(association_name).map(&:destroy)
      end

      def assign_nested_attributes_for_one_association(association_name, attributes)
        association = self.class.associations[association_name]
        if association.embeddable?
          assign_nested_attributes_for_one_embedded_association(association_name, attributes)
        else
          self.autosave[association_name] = true
          assign_nested_attributes_for_one_linked_association(association_name, attributes)
        end
      end
      
      def assign_nested_attributes_for_one_embedded_association(association_name, attributes)
        send(association_name).build(attributes.except(*UNASSIGNABLE_KEYS))
      end

      def assign_nested_attributes_for_one_linked_association(association_name, attributes)
        attributes = attributes.stringify_keys
        options = nested_attributes_options[association_name]

        if attributes[key_attr.to_s].blank? && !reject_new_record?(association_name, attributes)
          send(association_name).build(attributes.except(*UNASSIGNABLE_KEYS))
        else
          if ((existing_record = send(association_name)).key.to_s == attributes[key_attr.to_s].to_s)
            assign_to_or_mark_for_destruction(existing_record, attributes, association_name, options[:allow_destroy])
          else
            raise ArgumentError, "Attempting to update a child that isn't already associated to the parent."
          end
        end
      end

      def assign_nested_attributes_for_many_association(association_name, attributes_collection)
        unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
          raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
        end

        if attributes_collection.is_a? Hash
          attributes_collection = attributes_collection.sort_by { |index, _| index.to_i }.map { |_, attributes| attributes }
        end

        association = self.class.associations[association_name]
        if association.embeddable?
          assign_nested_attributes_for_many_embedded_association(association_name, attributes_collection)
        else
          self.autosave[association_name] = true
          assign_nested_attributes_for_many_linked_association(association_name, attributes_collection)
        end
      end

      def assign_nested_attributes_for_many_embedded_association(association_name, attributes_collection)
        options = nested_attributes_options[association_name]
        send(:"#{association_name}=", []) # Clobber existing
        attributes_collection.each do |attributes|
          attributes = attributes.stringify_keys
          if !reject_new_record?(association_name, attributes)
            send(association_name).build(attributes.except(*UNASSIGNABLE_KEYS))
          end
        end
      end

      def assign_nested_attributes_for_many_linked_association(association_name, attributes_collection)
        options = nested_attributes_options[association_name]
        attributes_collection.each do |attributes|
          attributes = attributes.stringify_keys

          if attributes[key_attr.to_s].blank? && !reject_new_record?(association_name, attributes)
            send(association_name).build(attributes.except(*UNASSIGNABLE_KEYS))
          elsif existing_record = send(association_name).detect { |record| record.key.to_s == attributes[key_attr.to_s].to_s }
            assign_to_or_mark_for_destruction(existing_record, attributes, association_name, options[:allow_destroy])
          end
        end
      end
    end

    def assign_to_or_mark_for_destruction(record, attributes, association_name, allow_destroy)
      if has_destroy_flag?(attributes) && allow_destroy
        (self.marked_for_destruction[association_name] ||= []) << record
      else
        record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
      end
    end
    
    def has_destroy_flag?(hash)
      TRUE_VALUES.include?(hash.stringify_keys['_destroy'])
    end

    def reject_new_record?(association_name, attributes)
      has_destroy_flag?(attributes) || call_reject_if(association_name, attributes)
    end

    def call_reject_if(association_name, attributes)
      attributes = attributes.stringify_keys
      case callback = nested_attributes_options[association_name][:reject_if]
      when Symbol
        method(callback).arity == 0 ? send(callback) : send(callback, attributes)
      when Proc
        callback.call(attributes)
      end
    end

  end
  
end
