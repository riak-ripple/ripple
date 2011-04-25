require 'active_support/concern'
require 'active_support/inflector'

module Ripple
  module EmbeddedDocument
    # @private
    module Finders
      extend ActiveSupport::Concern

      module ClassMethods
        def instantiate(attrs)
          begin
            klass = attrs['_type'].present? ? attrs['_type'].constantize : self
            klass.new(attrs)
          rescue NameError
            new(attrs)
          end
        end
      end
      
    end
  end
end
