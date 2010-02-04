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
  module Document
    module Persistence
      extend ActiveSupport::Concern
      
      module InstanceMethods
        # @private
        def initialize
          super
          @new = true
        end

        # Determines whether this is a new document.
        def new?
          @new || false
        end
        alias :new_record? :new?

        # Saves the document in Riak.
        # @return [true,false] whether the document succeeded in saving
        def save
          @robject ||= Riak::RObject.new(self.class.bucket, key)
          @robject.content_type = "application/json"
          @robject.data = attributes_for_persistence
          @robject.store
          self.key = @robject.key
          @new = false
          true
        rescue Riak::FailedRequest => fr
          false
        end

        # Reloads the document from Riak
        # @return self
        def reload
          return self if new?
          @robject.reload(:force => true)
          @attributes.merge!(@robject.data)
          self
        end
        
        private
        def attributes_for_persistence
          self.class.superclass < Ripple::Document ? attributes.merge("_type" => self.class.name) : attributes
        end
      end
    end
  end
end
