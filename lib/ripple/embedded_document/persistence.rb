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
  module EmbeddedDocument
    module Persistence
      extend ActiveSupport::Concern

      included do
        attr_accessor :_root_document
        delegate_method_to_root :new?, :save, :save!
      end
      
      module ClassMethods
        def embedded_in(parent)
          define_method(parent) { @_root_document }
        end
        
        def delegate_method_to_root(*methods)
          Array(methods).each do |method|
            define_method(method) { @_root_document ? @_root_document.send(method.to_sym) : super }
          end
        end
      end
      
      module InstanceMethods
        def attributes_for_persistence
          attributes.merge("_type" => self.class.name).merge(embedded_attributes_for_persistence)
        end
        
        def embedded_attributes_for_persistence
          self.class.associations.keys.inject({}) do |hash, name|
            hash["_#{name}"] = @attributes["_#{name}"] if @attributes["_#{name}"]
            hash
          end
        end
      end
    end
  end
end
