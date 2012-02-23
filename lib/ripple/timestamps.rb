require 'active_support/time'
require 'active_support/concern'

module Ripple
  # Adds automatic creation and update timestamps to a
  # {Ripple::Document} model.
  module Timestamps
    extend ActiveSupport::Concern

    module ClassMethods
      # Adds the :created_at and :updated_at timestamp properties to
      # the document.
      def timestamps!(options={})
        property :created_at, Time, options.merge(:default => proc { Time.now })
        property :updated_at, Time, options.dup
        before_save :touch
      end
    end

    # Sets the :updated_at attribute before saving the document.
    def touch
      self.updated_at = Time.now
    end
  end
end
