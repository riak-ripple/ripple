
require 'riak/util/translation'

module Riak
  class MapReduce
    # Builds key-filter lists for MapReduce inputs in a DSL-like fashion.
    class FilterBuilder
      include Util::Translation

      # Known filters available in riak_kv_mapred_filters, mapped to
      # their arities. These are turned into instance methods.
      # Example:
      #
      #    FilterBuilder.new do
      #      string_to_int
      #      less_than 50
      #    end
      FILTERS = {
        :int_to_string => 0,
        :string_to_int => 0,
        :float_to_string => 0,
        :string_to_float => 0,
        :to_upper => 0,
        :to_lower => 0,
        :tokenize => 2,
        :urldecode => 0,
        :greater_than => 1,
        :less_than => 1,
        :greater_than_eq => 1,
        :less_than_eq => 1,
        :between => [2,3],
        :matches => 1,
        :neq => 1,
        :eq => 1,
        :set_member => -1,
        :similar_to => 2,
        :starts_with => 1,
        :ends_with => 1
      }

      # Available logical operations for joining filter chains. These
      # are turned into instance methods with leading underscores,
      # with aliases to uppercase versions.
      # Example:
      #
      #    FilterBuilder.new do
      #      string_to_int
      #      AND do
      #        seq { greater_than_eq 50 }
      #        seq { neq 100 }
      #      end
      #    end
      LOGICAL_OPERATIONS = %w{and or not}

      FILTERS.each do |f,arity|
        arities = [arity].flatten

        define_method(f) { |*args|
          unless arities.include?(-1) or arities.include?(args.size)
            raise ArgumentError.new t("filter_arity_mismatch",
              :filter => f,
              :expected => arities,
              :received => args.size
            )
          end

          @filters << [f, *args]
        }
      end

      LOGICAL_OPERATIONS.each do |op|
        # NB: string eval is needed here because in ruby 1.8, blocks can't yield to
        # other blocks
        class_eval <<-CODE
          def _#{op}(&block)
            raise ArgumentError.new(t('filter_needs_block', :filter => '#{op}')) unless block_given?
            @filters << [:#{op}, self.class.new(&block).to_a]
          end
          alias :#{op.to_s.upcase} :_#{op}
        CODE
      end

      # Creates a new FilterBuilder. Pass a block that will be
      # instance_eval'ed to construct the sequence of filters.
      def initialize(&block)
        @filters = []
        instance_eval(&block) if block_given?
      end

      # Wraps multi-step filters for use inside logical
      # operations. Does not correspond to an actual filter.
      def sequence(&block)
        @filters << self.class.new(&block).to_a
      end
      alias :seq :sequence

      # @return A list of filters for handing to the MapReduce inputs.
      def to_a
        @filters
      end
    end
  end
end
