class Person
  include Ripple::Document
  many :tasks
end

class Task
  include Ripple::Document
end
