class IndexedAddress
  include Ripple::EmbeddedDocument
  property :street, String, :index => true
  property :city, String, :index => true
end

class Indexer
  include Ripple::Document

  property :name, String, :index => true
  property :age, Fixnum, :index => true
  one :primary_address, :class => IndexedAddress
  many :addresses, :class => IndexedAddress
  index :name_age, String do
    if self.name && self.age
      "#{self.name}-#{self.age}"
    end
  end
  index :name_greeting, String

  def name_greeting
    if name
      "#{name}: Hello!"
    end
  end
end

class SubIndexer < Indexer
  property :height, String, :index => true
end
