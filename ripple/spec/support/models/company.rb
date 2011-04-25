class Company
  include Ripple::Document
  property :name, String
  many :departments
  many :invoices # linked
  one :ceo, :class_name => 'CEO'
end

class Department
  include Ripple::EmbeddedDocument
  property :name, String
  many :managers
end

class Manager
  include Ripple::EmbeddedDocument
  property :name, String
end

class CEO
  include Ripple::EmbeddedDocument
  property :name, String
end
