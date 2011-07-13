require 'ripple/associations/proxy'
require 'ripple/associations/many'

module Ripple
  module Associations
    class ManyStoredKeyProxy < Proxy
      include Many

      def count
        owner_keys.size
      end

      def <<(value)
        @reflection.verify_type!([value], @owner)

        raise "Unable to append if the document isn't first saved." if value.new_record?
        append_key_for(value)

        self
      end

      def replace(value)
        @reflection.verify_type!(value, @owner)

        reset_keys
        value.each do |doc|
          append_key_for(doc)
          doc.save!
        end
      end

      def delete(value)
        keys.delete(value.key)
        owner_keys.delete(value.key)
        self
      end

      def keys
        @keys ||= Set.new(owner_keys)
      end

      def reset
        @keys = nil
        super
      end

      def include?(document)
        return false unless document.respond_to?(:robject)
        return false unless document.robject.bucket.name == @reflection.bucket_name
        keys.include?(document.key)
      end


      protected
      def find_target
        klass.find(keys.to_a)
      end

      def append_key_for(value)
        keys << value.key
        owner_keys << value.key
      end

      def keys_name
        "#{@reflection.name.to_s.singularize}_keys"
      end

      def reset_keys
        @owner.send("#{keys_name}=", @owner.class.properties[keys_name].type.new)
        @keys = nil
      end

      def owner_keys
        if @owner.send(keys_name).nil?
          reset_keys
        end
        @owner.send(keys_name)
      end
    end
  end
end
