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
    module Key
      extend ActiveSupport::Concern

      module ClassMethods
        # Defines the key to be derived from a property.
        # @param [String,Symbol] prop the property to derive the key from
        def key_on(prop)
          class_eval <<-CODE
          def key
            #{prop}.to_s
          end
          def key=(value)
            self.#{prop} = value
          end
          def key_attr
            :#{prop}
          end          
          CODE
        end
      end
      
      module InstanceMethods
        # Reads the key for this Document.
        def key
          @key
        end
        
        # Sets the key for this Document.
        def key=(value)
          @key = value.to_s
        end

        def key_attr
          :key
        end        
      end
    end
  end
end
