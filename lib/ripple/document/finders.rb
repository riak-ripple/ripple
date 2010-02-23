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
  module Document
    module Finders
      extend ActiveSupport::Concern

      module ClassMethods
        # Retrieve single or multiple documents from Riak.
        # @overload find(key)
        #   Find a single document.
        #   @param [String] key the key of a document to find
        #   @return [Document] the found document, or nil
        # @overload find(key1, key2, ...)
        #   Find a list of documents.
        #   @param [String] key1 the key of a document to find
        #   @param [String] key2 the key of a document to find
        #   @return [Array<Document>] a list of found documents, including nil for missing documents
        # @overload find(keylist)
        #   Find a list of documents.
        #   @param [Array<String>] keylist an array of keys to find
        #   @return [Array<Document>] a list of found documents, including nil for missing documents
        def find(*args)
          args.flatten!
          return [] if args.length == 0
          return find_one(args.first) if args.length == 1
          args.map {|key| find_one(key) }
        end

        # Find all documents in the Document's bucket and return them.
        # @overload all()
        #   Get all documents and return them in an array.
        #   @return [Array<Document>] all found documents in the bucket
        # @overload all() {|doc| ... }
        #   Stream all documents in the bucket through the block.
        #   @yield [Document] doc a found document
        def all
          if block_given?
            bucket.keys do |keys|
              keys.each do |key|
                obj = find_one(key)
                yield obj if obj
              end
            end
            []
          else
            bucket.keys.inject([]) do |acc, k|
              obj = find_one(k)
              obj ? acc << obj : acc
            end
          end
        end

        private
        def find_one(key)
          instantiate(bucket.get(key))
        rescue Riak::FailedRequest => fr
          return nil if fr.code.to_i == 404
          raise fr
        end

        def instantiate(robject)
          klass = robject.data['_type'].constantize rescue self
          klass.new(robject.data.merge('key' => robject.key)).tap do |doc|
            doc.instance_variable_set(:@new, false)
            doc.instance_variable_set(:@robject, robject)
          end
        end
      end
    end
  end
end
