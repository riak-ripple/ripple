
require 'active_support/concern'
require 'active_model/observing'

module Ripple
  module Observable
    extend ActiveSupport::Concern
    include ActiveModel::Observing

    included do
      set_callback(:create, :before)     { notify_observers :before_create }
      set_callback(:create, :after)      { notify_observers :after_create }

      set_callback(:update, :before)     { notify_observers :before_update }
      set_callback(:update, :after)      { notify_observers :after_update }

      set_callback(:save, :before)       { notify_observers :before_save }
      set_callback(:save, :after)        { notify_observers :after_save }

      set_callback(:destroy, :before)    { notify_observers :before_destroy }
      set_callback(:destroy, :after)     { notify_observers :after_destroy }

      set_callback(:validation, :before) { notify_observers :before_validation }
      set_callback(:validation, :after)  { notify_observers :after_validation }
    end

  end
end
