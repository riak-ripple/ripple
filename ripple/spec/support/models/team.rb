class Team
  include Ripple::Document
  many :players
  validates_associated :players
end

class Player
  include Ripple::Document
  property :name, String, :presence => true
  property :position, String, :presence => true
end
