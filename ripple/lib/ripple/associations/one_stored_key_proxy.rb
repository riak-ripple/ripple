require 'ripple/associations/proxy'
require 'ripple/associations/one'

module Ripple
  module Associations
    class OneStoredKeyProxy < Proxy
      include One

      def replace(value)
        @reflection.verify_type!(value, owner)

        if value
          assign_key(value.key)
        else
          assign_key(nil)
        end

        @target = value
        loaded
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