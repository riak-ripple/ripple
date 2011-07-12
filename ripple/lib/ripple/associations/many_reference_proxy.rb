require 'ripple/associations/proxy'
require 'ripple/associations/many'

module Ripple
  module Associations
    class ManyReferenceProxy < Proxy
      include Many

      def <<(value)
        @reflection.verify_type!([value], @owner)

        assign_key(value, @owner.key)

        self
      end

      protected
      def find_target
        klass.find(Ripple.client.search(klass.bucket_name, "#{key_name}: #{@owner.key}")["response"]["docs"].collect do |search_document|
          search_document["id"]
        end)
      end

      def key_name
        "#{@owner.class.name.underscore}_key"
      end

      def assign_key(target, key)
        target.send("#{key_name}=", key)
      end
    end
  end
end