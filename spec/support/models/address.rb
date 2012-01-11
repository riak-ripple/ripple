class Address
  include Ripple::EmbeddedDocument
  property :street, String, :presence => true
  property :kind,   String, :presence => true
  many :notes
  embedded_in :user
end

class SpecialAddress < Address
end
