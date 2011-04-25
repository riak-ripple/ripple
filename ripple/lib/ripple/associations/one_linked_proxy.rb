require 'ripple/associations/proxy'
require 'ripple/associations/one'
require 'ripple/associations/linked'

module Ripple
  module Associations
    class OneLinkedProxy < Proxy
      include One
      include Linked

      protected
      def find_target
        return nil if links.blank?

        robjs = robjects
        return nil if robjs.blank?

        klass.send(:instantiate, robjs.first)
      end
    end
  end
end
