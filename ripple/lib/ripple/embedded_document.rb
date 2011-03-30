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
  # Represents a document model that is composed into or stored in a parent
  # Document.  Embedded documents may also embed other documents, have
  # callbacks and validations, but are solely dependent on the parent Document.
  module EmbeddedDocument
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :Finders
    autoload :Persistence
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
  end
end
