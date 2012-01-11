require 'ripple/associations/proxy'
require 'ripple/associations/many'

module Ripple
  module Associations
    class ManyStoredKeyProxy < Proxy
      include Many

      def count
        keys.size
      end

      def <<(value)
        @reflection.verify_type!([value], @owner)

        raise "Unable to append if the document isn't first saved." if value.new_record?
        load_target
        @target << value
        keys << value.key

        self
      end

      def replace(value)
        @reflection.verify_type!(value, @owner)

        reset_owner_keys
        value.each { |doc| self << doc }
        @target = value
        loaded
      end

      def delete(value)
        keys.delete(value.key)
        self
      end

      def keys
        if @owner.send(keys_name).nil?
          reset_owner_keys
        end

        @owner.send(keys_name)
      end

      def reset
        super
        self.owner_keys = @owner.robject.data ? @owner.robject.data[keys_name] : []
      end

      def include?(document)
        return false unless document.respond_to?(:robject)
        return false unless document.robject.bucket.name == @reflection.bucket_name
        keys.include?(document.key)
      end

      def reset_owner_keys
        self.owner_keys = []
      end


      protected
      def find_target
        klass.find(keys.to_a)
      end

      def keys_name
        "#{@reflection.name.to_s.singularize}_keys"
      end

      def owner_keys=(new_keys)
        @owner.send("#{keys_name}=", @owner.class.properties[keys_name].type.new(new_keys))
      end
    end
  end
end
