require 'support/models/note'

class Address
  include Ripple::EmbeddedDocument
  property :street, String, :presence => true
  many :notes
  embedded_in :user
end