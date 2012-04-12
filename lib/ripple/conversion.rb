require 'active_model/conversion'

module Ripple
  # Provides ActionPack compatibility for {Ripple::Document} models.
  module Conversion
    extend  ActiveSupport::Concern
    include ActiveModel::Conversion

    # True if this is a new document
    def new_record?
      new?
    end

    # True if this is not a new document
    def persisted?
      !new?
    end

    # Converts to a view key
    def to_key
      new? ? nil : [key]
    end

    # Converts to a URL parameter
    def to_param
      key
    end
  end
end
