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

require 'active_support/concern'
require 'active_support/core_ext/hash/except'
require 'ripple/translation'
require 'ripple/embedded_document/finders'
require 'ripple/embedded_document/persistence'
require 'ripple/properties'
require 'ripple/attribute_methods'
require 'ripple/timestamps'
require 'ripple/validations'
require 'ripple/associations'
require 'ripple/callbacks'
require 'ripple/conversion'
require 'ripple/inspection'
require 'ripple/nested_attributes'
require 'ripple/serialization'

module Ripple
  # Represents a document model that is composed into or stored in a parent
  # Document.  Embedded documents may also embed other documents, have
  # callbacks and validations, but are solely dependent on the parent Document.
  module EmbeddedDocument
    extend ActiveSupport::Concern
    include Translation

    included do
      extend ActiveModel::Naming
      include Persistence
      extend Ripple::Properties
      include Ripple::AttributeMethods
      include Ripple::Timestamps
      include Ripple::Validations
      include Ripple::Associations
      include Ripple::Callbacks
      include Ripple::Conversion
      include Finders
      include Ripple::Inspection
      include Ripple::NestedAttributes
      include Ripple::Serialization
    end

    module ClassMethods
      def embeddable?
        true
      end
    end

    module InstanceMethods
      def ==(other)
        self.class == other.class &&
        _parent_document == other._parent_document &&
        attributes.except('_type') == other.attributes.except('_type')
      end
    end
  end
end
