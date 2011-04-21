require 'ripple/associations'
require 'set'

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
        @keys = nil
        @target = value
      end

      def keys
        @keys ||= Set.new(links.map { |l| l.key })
      end

      def reset
        super
        @keys = nil
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
