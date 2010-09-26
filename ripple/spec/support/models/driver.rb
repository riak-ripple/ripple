class Driver
  include Ripple::Document
  property :name, String
  key_on :name
end
