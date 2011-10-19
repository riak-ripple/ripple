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
            klass = attrs['_type'].present? ? attrs.delete('_type').constantize : self
          rescue NameError
            klass = self
          end
          klass.new.tap do |object|
            object.raw_attributes = attrs
            object.changed_attributes.clear
          end
        end
      end

    end
  end
end
