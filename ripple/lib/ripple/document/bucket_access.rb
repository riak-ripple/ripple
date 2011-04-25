require 'ripple'

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
        Ripple.client.bucket(bucket_name)
      end

      # Set the bucket name for this class and its subclasses.
      # @param [String] value the new bucket name
      def bucket_name=(value)
        (class << self; self; end).send(:define_method, :bucket_name){ value }
      end
    end
  end
end
