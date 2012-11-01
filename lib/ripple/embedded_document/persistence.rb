require 'active_support/concern'
require 'ripple/translation'

module Ripple
  # Exception raised when save is called on an EmbeddedDocument that
  # is not attached to a root Document.
  class NoRootDocument < StandardError
    include Translation
    def initialize(doc, method)
      super(t("no_root_document", :doc => doc.inspect, :method => method))
    end
  end

  module EmbeddedDocument
    # Adds methods to {Ripple::EmbeddedDocument} that delegate storage
    # operations to the parent document.
    module Persistence
      extend ActiveSupport::Concern

      module ClassMethods
        # Creates a method that points to the parent document.
        def embedded_in(parent)
          define_method(parent) { @_parent_document }
        end
      end

      # The parent document to this embedded document. This may be a
      # {Ripple::Document} or another {Ripple::EmbeddedDocument}.
      attr_accessor :_parent_document

      # Whether the root document is unsaved.
      def new?
        if _root_document
          _root_document.new?
        else
          true
        end
      end

      # Sets this embedded documents attributes and saves the root document.
      def update_attributes(attrs)
        self.attributes = attrs
        save
      end

      # Updates this embedded document's attribute and saves the
      # root document, skipping validations.
      def update_attribute(attribute, value)
        send("#{attribute}=", value)
        save(:validate => false)
      end

      # Saves this embedded document by delegating to the root document.
      def save(*args)
        if _root_document
          run_save_callbacks do
            _root_document.save(*args)
          end
        else
          raise NoRootDocument.new(self, :save)
        end
      end

      # @private
      def attributes_for_persistence
        raw_attributes.merge("_type" => self.class.name)
      end

      # The root {Ripple::Document} to which this embedded document belongs.
      def _root_document
        @_parent_document.try(:_root_document)
      end
    end
  end
end
