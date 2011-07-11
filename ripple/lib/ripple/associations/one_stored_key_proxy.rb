require 'ripple/associations/proxy'
require 'ripple/associations/one'

module Ripple
  module Associations
    class OneStoredKeyProxy < Proxy
      include One

      def replace(doc)
        @reflection.verify_type!(doc, owner)

        assign_key(doc.key)
      end

      protected

      def key
        @owner.send(key_name)
      end

      def assign_key(value)
        @owner.send("#{key_name}=", value)
      end

      def key_name
        "#{@reflection.name}_key"
      end

      def find_target
        return nil if key.blank?

        klass.find(key)
      end
    end
  end
end