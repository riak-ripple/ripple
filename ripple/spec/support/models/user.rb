
require 'support/models/address'
require 'support/models/profile'

class User
  include Ripple::Document
  many :addresses

  one :profile, :using => :key
end
