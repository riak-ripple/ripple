require 'ripple/callbacks'

module Ripple
  module EmbeddedDocument
    module AroundCallbacks
      extend ActiveSupport::Concern
      extend Translation

      included do
        Ripple::Callbacks::CALLBACK_TYPES.each do |type|
          define_singleton_method "around_#{type}" do |*args|
            raise NotImplementedError.new(t("around_callbacks_not_supported", :type => type))
          end
        end
      end
    end
  end
end
