require 'ripple/associations'

module Ripple
  module Associations
    module Many
      include Instantiators

      def to_ary
        load_target
        Array === target ? target.to_ary : Array.wrap(target)
      end

      def count
        load_target
        target.size
      end

      def reset
        super
        @target = []
      end

      def <<(value)
        raise NotImplementedError
      end

      alias_method :push, :<<
      alias_method :concat, :<<

      protected
      def instantiate_target(instantiator, attrs={})
        doc = klass.send(instantiator, attrs)
        self << doc
        doc
      end
    end
  end
end
