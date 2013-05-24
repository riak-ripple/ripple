class User
  include Ripple::Document
  property :email, String, presence: true

  key_on :email
end
