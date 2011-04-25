require 'active_support/concern'

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
