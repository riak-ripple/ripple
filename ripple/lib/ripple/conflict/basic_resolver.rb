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
        model_class.properties.each do |name, property|
          document.send(:"#{name}=", resolved_value_for(property))
        end
      end

      private

      def resolved_value_for(property)
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
    end
  end
end

