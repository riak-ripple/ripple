require 'ripple/associations/proxy'
require 'ripple/associations/one'

module Ripple
  module Associations
    class OneKeyProxy < Proxy
      include One

      def replace(doc)
        @reflection.verify_type!(doc, owner)

        reset_previous_target_key_delegate
        assign_new_target_key_delegate(doc)

        loaded
        @target = doc
      end

      def find_target
        klass.find(owner.key)
      end

      protected
      def instantiate_target(instantiator, attrs={})
        @target = super
        @target.key = owner.key
        @target
      end

      private
      def reset_previous_target_key_delegate
        @target.key_delegate = @target if @target
      end

      def assign_new_target_key_delegate(doc)
        doc.class.send(:include, Ripple::Associations::KeyDelegator) unless doc.class.include?(Ripple::Associations::KeyDelegator)
        owner.key_delegate = doc.key_delegate = owner
      end

    end

    module KeyDelegator
      attr_accessor :key_delegate

      def key_delegate
        @key_delegate || self
      end

      def key
        self === key_delegate ? super : key_delegate.key
      end

      def key=(value)
        self === key_delegate ? super(value) : key_delegate.key = value
      end
    end
  end
end
