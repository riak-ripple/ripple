class PaymentMethod
  include Ripple::Document
  property :account_key, String
end

class Account
  include Ripple::Document
  many :payment_methods, :using => :reference
end

class Transaction
  include Ripple::Document
  property :account_key, String
  one :account, :using => :stored_key
end
