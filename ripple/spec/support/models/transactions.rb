class Account
  include Ripple::Document
end

class Transaction
  include Ripple::Document
  property :account_key, String
  one :account, :using => :stored_key
end
