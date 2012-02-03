class Box
  include Ripple::Document
  property :shape, String
  many :sides, :class_name => 'BoxSide'
  validates_associated :sides
  timestamps!
end

class BoxSide
  include Ripple::EmbeddedDocument
  embedded_in :box
  property :material, String
end
