require 'ripple/associations/proxy'
require 'ripple/associations/many'

require 'set'

module Ripple
  module Associations
    class ManyReferenceProxy < Proxy
      include Many

      def <<(value)
        values = Array.wrap(value)
        @reflection.verify_type!(values, @owner)

        values.each {|v| assign_key(v) }
        load_target
        @target.merge values

        self
      end

      def replace(value)
        @reflection.verify_type!(value, @owner)
        delete_all
        Array.wrap(value).compact.each do |doc|
          assign_key(doc)
        end
        loaded
        @keys = nil
        @target = Set.new(value)
      end

      def delete_all
        load_target
        @target.each do |e|
          delete(e)
        end
      end

      def delete(value)
        load_target
        assign_key(value, nil)
        @target.delete(value)
      end

      def target
        load_target
        @target.to_a
      end

      def keys
        @keys ||= Ripple.client.search(klass.bucket_name, "#{key_name}: #{@owner.key}")["response"]["docs"].inject(Set.new) do |set, search_document|
          set << search_document["id"]
        end
      end

      def reset
        @keys = nil
        super
      end

      def include?(document)
        return false unless document.class.respond_to?(:bucket_name)

        return false unless document.class.bucket_name == @reflection.bucket_name
        keys.include?(document.key)
      end

      def count
        if loaded?
          @target.count
        else
          keys.count
        end
      end

      protected
      def find_target
        Set.new(klass.find(keys.to_a))
      end

      def key_name
        "#{@owner.class.name.underscore}_key"
      end

      def assign_key(target, key=@owner.key)
        if target.new_record?
          target.send("#{key_name}=", key)
        else
          target.update_attribute(key_name, key)
        end
      end
    end
  end
end
