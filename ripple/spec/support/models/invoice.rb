
class Invoice
  include Ripple::Document
  one :customer
  one :note
end