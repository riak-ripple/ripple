class Car
  include Ripple::Document
  
  property :make, String
  property :model, String

  one :driver       # linked, key_on :name
  many :passengers  # linked, standard :key
  one :engine       # embedded
  many :seats       # embedded
  many :wheels

  accepts_nested_attributes_for :driver, :passengers, :engine, :seats
  accepts_nested_attributes_for :wheels, :reject_if => proc{|attrs| attrs['diameter'] < 12 }, :allow_destroy => true
end
