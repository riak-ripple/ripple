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
    class OneEmbeddedProxy < Proxy
      include One
      include Embedded

      def replace(doc)
        @reflection.verify_type!(doc, @owner)
        @_doc = doc.respond_to?(:attributes_for_persistence) ? doc.attributes_for_persistence : doc
        assign_references(doc)

        if doc.is_a?(@reflection.klass)
          loaded
          @target = doc
        else
          reset
        end

        @_doc
      end

      protected
      def find_target
        return nil unless @_doc
        klass.instantiate(@_doc).tap do |doc|
          assign_references(doc)
        end
      end
    end
  end
end
