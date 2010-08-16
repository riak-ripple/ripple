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
require 'ripple/document'

module Ripple
  module Document
    # Similar to ActiveRecord's tables or MongoMapper's collections, we
    # provide a sane default bucket in which to store your documents.
    module BucketAccess
      # @return [String] The bucket name assigned to the document class.  Subclasses will inherit their bucket name from their parent class unless they redefine it.
      def bucket_name
        superclass.respond_to?(:bucket_name) ? superclass.bucket_name : model_name.plural
      end

      # @return [Riak::Bucket] The bucket assigned to this class.
      def bucket
        Riak::Bucket.new(Ripple.client, bucket_name)
      end

      # Set the bucket name for this class and its subclasses.
      # @param [String] value the new bucket name
      def bucket_name=(value)
        (class << self; self; end).send(:define_method, :bucket_name){ value }
      end
    end
  end
end
