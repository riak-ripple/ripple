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
require 'ripple'
require 'active_model/serialization'
require 'active_model/serializers/json'
require 'active_model/serializers/xml'

module Ripple
  # Provides methods for serializing Ripple documents to external
  # formats (e.g. JSON).  By default, embedded documents will be
  # included in the resulting format.
  module Serialization
    extend ActiveSupport::Concern
    include ::ActiveModel::Serializers::JSON

    module InstanceMethods
      # Creates a Hash suitable for conversion to an external format.
      # Called internally by {#to_json}.
      # @param [Hash] options (nil) serialization options
      # @option options [Array<Symbol>] :only emit only the specified attributes
      # @option options [Array<Symbol>] :except omit the specified attributes
      # @option options [Array<Symbol>, Hash] :include include the
      #      specified associations (with or without extra
      #      options). This defaults to all embedded associations.
      # @return [Hash] a hash of attributes and embedded documents
      def serializable_hash(options=nil)
        options = options.try(:clone) || {}

        unless options.has_key?(:include)
          options[:include] = self.class.embedded_associations.map(&:name)
        end

        hash = super(options)

        hash['key'] = key if respond_to?(:key) and key.present?

        serializable_add_includes(options) do |association, records, opts|
          hash[association.to_s] = records.is_a?(Enumerable) ? records.map {|r| r.serializable_hash(opts) } : records.serializable_hash(opts)
        end
        hash
      end

      private
      def serializable_add_includes(options={})
        return unless include_associations = options.delete(:include)

        base_only_or_except = {
          :except => options[:except],
          :only => options[:only]
        }

        include_has_options = include_associations.is_a?(Hash)
        associations = include_has_options ? include_associations.keys : Array.wrap(include_associations)

        for association in associations
          records = case self.class.associations[association.to_sym].type
                    when :many
                      send(association).to_a
                    when :one
                      send(association)
                    end

          unless records.nil?
            association_options = include_has_options ? include_associations[association] : base_only_or_except
            opts = options.merge(association_options)
            yield(association, records, opts)
          end
        end

        options[:include] = include_associations
      end
    end
  end
end
