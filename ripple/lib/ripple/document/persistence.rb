require 'active_support/concern'

module Ripple
  module Document
    module Persistence
      extend ActiveSupport::Concern

      module ClassMethods

        # Instantiates a new record, applies attributes from a block, and saves it
        def create(attrs={}, &block)
          new(attrs, &block).tap {|s| s.save }
        end

        # Destroys all records one at a time.
        # Place holder while :delete to bucket is being developed.
        def destroy_all
          list(&:destroy)
        end

        attr_writer :quorums
        alias_method "set_quorums", "quorums="

        def quorums
          @quorums ||= {}
        end
      end

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

        # Updates a single attribute and then saves the document
        # NOTE: THIS SKIPS VALIDATIONS! Use with caution.
        # @return [true,false] whether the document succeeded in saving
        def update_attribute(attribute, value)
          send("#{attribute}=", value)
          save(:validate => false)
        end

        # Writes new attributes and then saves the document
        # @return [true,false] whether the document succeeded in saving
        def update_attributes(attrs)
          self.attributes = attrs
          save
        end

        # Saves the document in Riak.
        # @return [true,false] whether the document succeeded in saving
        def save(*args)
          really_save(*args)
        end

        def really_save(*args)
          update_robject
          robject.store(self.class.quorums.slice(:w,:dw))
          self.key = robject.key
          @new = false
          true
        end

        # Reloads the document from Riak
        # @return self
        def reload
          return self if new?
          robject.reload(:force => true)
          self.__send__(:raw_attributes=, @robject.data.except("_type"))
          reset_associations
          self
        end

        # Deletes the document from Riak and freezes this instance
        def destroy
          robject.delete(self.class.quorums.slice(:rw)) unless new?
          freeze
          true
        rescue Riak::FailedRequest
          false
        end

        # Freezes the document, preventing further modification.
        def freeze
          @attributes.freeze; super
        end

        attr_writer :robject

        def robject
          @robject ||= Riak::RObject.new(self.class.bucket, key).tap do |obj|
            obj.content_type = "application/json"
          end
        end

        def update_robject
          robject.key = key if robject.key != key
          robject.content_type = 'application/json'
          robject.data = attributes_for_persistence
        end

        private
        def attributes_for_persistence
          raw_attributes.merge("_type" => self.class.name)
        end
      end
    end
  end
end
