require 'support/models/address'

class User
  include Ripple::Document
  many :addresses
end