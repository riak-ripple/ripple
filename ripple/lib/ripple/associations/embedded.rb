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

module Ripple
  module Associations
    module Embedded

      def initialize(*args)
        super
        lazy_load_validates_associated
      end

      protected
      
      def lazy_load_validates_associated
        return if @owner.class.validators_on(@reflection.name).any? {|v| Ripple::Validations::AssociatedValidator === v}
        @owner.class.validates @reflection.name, :associated => true
      end

      def assign_references(docs)
        Array(docs).each do |doc|
          next unless doc.respond_to?(:_parent_document=)
          doc._parent_document = owner
        end
      end

      def instantiate_target(*args)
        doc = super
        assign_references(doc)
        doc
      end

    end
  end
end
