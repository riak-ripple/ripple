module Ripple
  module Conflict
    module TestHelper
      def create_conflict(main_record, *modifiers)
        # We have to disable all on conflict resolvers while we create conflict
        # so that they don't auto-resolve it.
        orig_hooks = Riak::RObject.on_conflict_hooks.dup
        Riak::RObject.on_conflict_hooks.clear

        begin
          klass, key = main_record.class, main_record.key
          records = modifiers.map { |_| klass.find!(key) }

          records.zip(modifiers).each do |(record, modifier)|
            # necessary to get conflict, so riak thinks they are being saved by different clients
            Ripple.client.client_id += 1

            modifier.call(record)
            record.save!
          end

          robject = klass.bucket.get(key)
          raise "#{robject} is not in conflict as expected." unless robject.conflict?
        ensure
          orig_hooks.each do |hook|
            Riak::RObject.on_conflict(&hook)
          end
        end
      end
    end
  end
end

