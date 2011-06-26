module Ripple
  module Conflict
    module DocumentHooks
      extend ActiveSupport::Concern

      module ClassMethods
        attr_reader :on_conflict_block

        def on_conflict(*expected_conflicts, &block)
          @expected_conflicts = expected_conflicts
          @on_conflict_block = block
        end

        def expected_conflicts
          @expected_conflicts ||= []
        end

        private

        def instantiate(robject)
          return super unless robject.conflict?

          resolver = Ripple::Conflict::Resolver.new(robject, self)
          resolver.resolve
          resolver.document
        end
      end
    end
  end
end
