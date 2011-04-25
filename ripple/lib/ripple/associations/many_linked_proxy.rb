require 'ripple/associations/proxy'
require 'ripple/associations/many'
require 'ripple/associations/linked'

module Ripple
  module Associations
    class ManyLinkedProxy < Proxy
      include Many
      include Linked

      def <<(value)
        load_target
        new_target = @target.concat(Array(value))
        replace new_target
        self
      end

      def delete(value)
        load_target
        @target.delete(value)
        replace @target
        self
      end

      protected
      def find_target
        robjects.map {|robj| klass.send(:instantiate, robj) }
      end
    end
  end
end
