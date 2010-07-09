class Person
  include Ripple::Document
  many :tasks
  one :profile
end

class Task
  include Ripple::Document
end

class Profile
  include Ripple::Document
end
