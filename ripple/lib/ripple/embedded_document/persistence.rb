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

      module InstanceMethods
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
            _root_document.save(*args)
          else
            raise NoRootDocument.new(self, :save)
          end
        end

        # @private
        def attributes_for_persistence
          attributes.merge("_type" => self.class.name)
        end

        # The root {Ripple::Document} to which this embedded document belongs.
        def _root_document
          @_parent_document.try(:_root_document)
        end
      end
    end
  end
end
