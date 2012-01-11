class CreditCard
  include Ripple::Document
  one :user, :using => :key
  property :number, Integer
end
