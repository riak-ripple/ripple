require 'ripple/conflict/basic_resolver'

module Ripple
  module Conflict
    class Resolver
      include Translation

      attr_reader :document, :model_class

      delegate :expected_conflicts, :on_conflict_block, :to => :model_class

      def self.to_proc
        @to_proc ||= lambda do |robject|
          possible_model_classes = robject.siblings.map { |s| s.data && s.data['_type'] }.compact.uniq
          return nil unless possible_model_classes.size == 1

          resolver = new(robject, possible_model_classes.first.constantize)
          resolver.resolve
          resolver.document.robject
        end
      end

      Riak::RObject.on_conflict(&self)

      def initialize(robject, model_class)
        @robject = robject
        @model_class = model_class
      end

      def resolve
        assert_conflict_block
        basic_resolver.perform
        assert_no_unexpected_conflicts
        document.instance_exec(siblings, basic_resolver.remaining_conflicts, &on_conflict_block)
        document.update_robject
      end

      def siblings
        @siblings ||= @robject.siblings.map do |s|
          @model_class.send(:instantiate, select_sibling(s)).tap do |record|
            # TODO: make the deleted conditional explicit by putting logic in
            #       RObject to know it has loaded a deleted sibling.
            #       Here we assume it is deleted if the data is nil because
            #       that's the only way we know of that the data can be nil.
            record.instance_variable_set(:@deleted, true) if s.data.nil?
          end
        end
      end

      def document
        # pick a sibling robject to use as the basis of the document to resolve
        # which one doesn't really matter.
        @document ||= @model_class.send(:instantiate, select_sibling(@robject.siblings.first))
      end

      private

      def basic_resolver
        @basic_resolver ||= BasicResolver.new(self)
      end

      def assert_conflict_block
        return if on_conflict_block

        raise NotImplementedError, t('conflict_handler_not_implemented', :document => document)
      end

      def assert_no_unexpected_conflicts
        return unless basic_resolver.unexpected_conflicts.any?

        raise NotImplementedError, t('unexpected_conflicts',
          :conflicts => basic_resolver.unexpected_conflicts.inspect,
          :document  => document.inspect
        )
      end

      if defined? Riak::RContent
        def select_sibling(sibling)
          # riak-client 1.1.0+ makes the siblings a different class,
          # as they should be. We need to make a new RObject to hold
          # only this sibling.
          sibling.robject.dup.tap do |robject|
            robject.siblings = [ sibling.dup ]
          end
        end
      else
        def select_sibling(sibling)
          # riak-client 1.0.x and earlier makes the siblings RObjects,
          # so we can use this sibling as-is after duplication.
          sibling.dup
        end
      end
    end
  end
end

