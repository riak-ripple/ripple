module Ripple
  module Document
    module Timestamps
      extend ActiveSupport::Concern

      module ClassMethods
        def timestamps!
          property :created_at, Time, :default => proc { Time.now.utc }
          property :updated_at, Time
          before_save :touch
        end
      end

      module InstanceMethods
        def touch
          self.updated_at = Time.now.utc
        end
      end

    end
  end
end