module Ripple
  module Conflict
    module DocumentHooks
      extend ActiveSupport::Concern

      module ClassMethods
        # @return [Proc] the registered conflict handler
        attr_reader :on_conflict_block

        # Registers a conflict handler for this model.
        #
        # @param [Array<Symbol>] expected_conflicts the list of properties and associations
        #                        you expect to be in conflict.
        # @yield the conflict handler block
        # @yieldparam [Array<Ripple::Document>] siblings the sibling documents
        # @yieldparam [Array<Symbol>] conflicts the properties and associations that could not
        #                             be resolved by ripple's basic resolution logic.
        #
        # The block is instance_eval'd in the context of a partially resolved model instance.
        # Thus, you should apply your resolution logic directly to self. Before calling
        # your block, Ripple attempts some basic resolution on your behalf:
        #
        # * Any property or association for which all siblings agree will be set to the common value.
        # * created_at will be set to the minimum value.
        # * updated_at will be set to the maximum value.
        # * All other properties and associations will be set to the default: nil or the default
        #   value for a property, nil for a one association, and an empty array for a many association.
        #
        # Note that any conflict you do not resolve is a potential source of data loss (since ripple
        # sets it to a default such as nil). It is recommended (but not required) that you pass the list
        # of expected conflicts, as that informs ripple of what conflicts your block handles. If it detects
        # conflicts for any other properties or associations, a NotImplementedError will be raised.
        def on_conflict(*expected_conflicts, &block)
          @expected_conflicts = expected_conflicts
          @on_conflict_block = block
        end

        # @return [Array<Symbol>] list of properties and associations that are expected
        #                         to be in conflict.
        def expected_conflicts
          @expected_conflicts ||= []
        end
      end
    end
  end
end
