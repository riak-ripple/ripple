# class IndexedAddress
#   include Ripple::EmbeddedDocument
#   property :street, String, :index => true
#   property :city, String, :index => true
# end

class Indexer
  include Ripple::Document
  
  property :name, String, :index => true
  property :age, Fixnum, :index => true
  # many :indexed_addresses
end
