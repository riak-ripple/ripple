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
  class NoRootDocument < StandardError
    include Translation
    def initialize(doc, method)
      super(t("no_root_document", :doc => doc.inspect, :method => method))
    end
  end
  
  module EmbeddedDocument
    module Persistence
      extend ActiveSupport::Concern
      
      module ClassMethods
        def embedded_in(parent)
          define_method(parent) { @_parent_document }
        end
      end
      
      module InstanceMethods
        
        attr_reader :_parent_document
        
        def embeddable?
          self.class.embeddable?
        end
        
        def new?
          if _root_document?
            super
          elsif @_root_document
            _root_document.new?
          else
            true
          end
        end
        
        # because alias_method doesn't like super
        def new_record?; new?; end
        
        # for ActiveModel::Conversion
        def persisted?; !new?; end
        
        def save(*args)
          if _root_document?
            super
          elsif @_root_document
            _root_document.save(*args)
          else
            raise NoRootDocument.new(self, :save)
          end
        end
        
        def save!(*args)
          if _root_document?
            super
          elsif @_root_document
            _root_document.save!(*args)
          else
            raise NoRootDocument.new(self, :save!)
          end
        end
        
        def _root_document
          embeddable? ? @_root_document : self
        end
        
        def _root_document?
          _root_document === self
        end

        def attributes_for_persistence
          attributes.merge("_type" => self.class.name).merge(embedded_attributes_for_persistence)
        end
        
        def _parent_document=(value)
          @_root_document   = value._root_document
          @_parent_document = value
        end
        
        protected
        
          def embedded_attributes_for_persistence
            embedded_associations.inject({}) do |attrs, association|
              if documents = instance_variable_get(association.ivar)
                attrs[association.name] = documents.is_a?(Array) ? documents.map(&:attributes_for_persistence) : documents.attributes_for_persistence
              end
              attrs
            end
          end
      end
    end
  end
end
