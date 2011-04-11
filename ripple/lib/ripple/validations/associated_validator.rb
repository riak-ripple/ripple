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
#
# Taken from ActiveRecord::Validations::AssociatedValidators
#
require 'active_model/validator'

module Ripple
  module Validations
    class AssociatedValidator < ActiveModel::EachValidator
      include Translation
      def validate_each(record, attribute, value)
        return if (value.is_a?(Array) ? value : [value]).collect{ |r| r.nil? || r.valid? }.all?
        record.errors.add(attribute, error_message_for(attribute, value))
      end

      private

        def error_message_for(attribute, associated_records)
          if associated_records.respond_to?(:each_with_index)
            record_errors = associated_records.enum_for(:each_with_index).collect do |record, index|
              next unless record.errors.any?

              t("associated_document_error_summary",
                :doc_type => attribute.to_s.singularize,
                :doc_id => index + 1,
                :errors => record.errors.full_messages.to_sentence
              )
            end
            record_errors.compact!
            record_errors.flatten!

            t("many_association_validation_error",
              :association_errors => record_errors.join('; '))
          else
            t("one_association_validation_error",
              :association_errors => associated_records.errors.full_messages.to_sentence)
          end
        end
    end

    module ClassMethods
      def validates_associated(*attr_names)
        validates_with AssociatedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
