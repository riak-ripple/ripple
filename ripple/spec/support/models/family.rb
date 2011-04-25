class Parent
  include Ripple::Document
  one :child
  validates_associated :child
end

class Child
  include Ripple::EmbeddedDocument
  property :name, String, :presence => true
  property :age, Integer, :presence => true
  one :gchild, :class_name => 'Grandchild'
end

class Grandchild
  include Ripple::EmbeddedDocument
end
