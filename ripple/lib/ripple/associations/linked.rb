require 'ripple/associations'

module Ripple
  module Associations
    module Linked
      def replace(value)
        @reflection.verify_type!(value, @owner)
        @owner.robject.links -= links
        Array(value).compact.each do |doc|
          doc.save if doc.new?
          @owner.robject.links << doc.to_link(@reflection.link_tag)
        end
        loaded
        @target = value
      end

      protected
      def links
        @owner.robject.links.select(&@reflection.link_filter)
      end

      def robjects
        @owner.robject.walk(*Array(@reflection.link_spec)).first || []
      rescue
        []
      end
    end
  end
end
