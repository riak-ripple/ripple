module Ripple
  module Conflict
    class BasicResolver
      delegate :model_class, :document, :siblings, :to => :@main_resolver

      def initialize(main_resolver)
        @main_resolver = main_resolver
      end

      def remaining_conflicts
        @remaining_conflicts ||= []
      end

      def unexpected_conflicts
        # if the user didn't specify the conflict they expect,
        # then don't consider any conflicts unexpected
        return [] if model_class.expected_conflicts.blank?

        remaining_conflicts - model_class.expected_conflicts
      end

      def perform
        process_properties
        process_embedded_associations
        process_linked_associations
      end

      private

      def process_properties
        model_class.properties.each do |name, property|
          document.send(:"#{name}=", resolved_property_value_for(property))
        end
      end

      def process_embedded_associations
        model_class.embedded_associations.each do |assoc|
          document.send(:"#{assoc.name}=", resolved_association_value_for(assoc, :load_target))
        end
      end

      def process_linked_associations
        model_class.linked_associations.each do |assoc|
          document.send(assoc.name).replace_links(resolved_association_value_for(assoc, :links))
        end
      end

      def resolved_property_value_for(property)
        uniq_values = siblings.map(&property.key).uniq

        value = if uniq_values.size == 1
          uniq_values.first
        elsif property.key == :updated_at
          uniq_values.compact.max
        elsif property.key == :created_at
          uniq_values.compact.min
        else
          remaining_conflicts << property.key
          property.default
        end
      end

      def resolved_association_value_for(association, proxy_value_method)
        # the association proxy doesn't uniquify well, so we have to use the target or links directly
        uniq_values = siblings.map { |s| s.send(association.name).__send__(proxy_value_method) }.uniq

        return uniq_values.first if uniq_values.size == 1
        remaining_conflicts << association.name

        association.many? ? [] : nil # default value
      end
    end
  end
end

