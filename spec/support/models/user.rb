class User
  include Ripple::Document
  many :addresses

  one :profile, :using => :key
  one :user_profile

  property :email, String, :presence => true
  many :friends, :class_name => "User"
  one :emergency_contact, :class_name => "User"
  one :credit_card, :using => :key
end

class UserProfile
  include Ripple::EmbeddedDocument
  property :name, String, :presence => true
  embedded_in :user
end
