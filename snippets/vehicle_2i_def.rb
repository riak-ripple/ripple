class Vehicle
  include Ripple::Document

  property :license, String, presence: true, index: true
end
