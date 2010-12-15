# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require 'riak'

module Riak
  class MapReduce
    # Builds key-filter lists for MapReduce inputs in a DSL-like fashion.
    class FilterBuilder
      include Util::Translation

      # Known filters available in riak_kv_mapred_filters, mapped to
      # their arities.
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
        :between => 2,
        :matches => 1,
        :neq => 1,
        :eq => 1,
        :set_member => 1,
        :similar_to => 1,
        :starts_with => 1,
        :ends_with => 1
      }

      LOGICAL_OPERATIONS = %w{and or not}

      FILTERS.each do |f,arity|
        class_eval <<-CODE
          def #{f}(*args)
            raise ArgumentError.new(t("filter_arity_mismatch", :filter => :#{f}, :expected => #{arity}, :received => args.size)) unless args.size == #{arity}
            @filters << ([:#{f}] + args)
          end
        CODE
      end

      LOGICAL_OPERATIONS.each do |op|
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
