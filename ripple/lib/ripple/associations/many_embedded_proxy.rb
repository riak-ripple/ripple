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
    class ManyEmbeddedProxy < Proxy
      include Many
      include Embedded

      def <<(docs)
        load_target
        @reflection.verify_type!(Array(docs), @owner)
        assign_references(docs)
        @target += Array(docs)
        self
      end

      def replace(docs)
        @reflection.verify_type!(docs, @owner)
        @_docs = docs.map { |doc| attrs = doc.respond_to?(:attributes_for_persistence) ? doc.attributes_for_persistence : doc }
        assign_references(docs)
        reset
        @_docs
      end

      protected
      def find_target
        (@_docs || []).map do |attrs|
          klass.instantiate(attrs).tap do |doc|
            assign_references(doc)
          end
        end
      end

    end
  end
end
