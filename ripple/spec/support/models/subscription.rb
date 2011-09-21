class Subscription
  include Ripple::Document

  class MyCustomType
    attr_accessor :foo

    def initialize(foo)
      self.foo = foo
    end

    def as_json(options = {})
      foo
    end

    def self.ripple_cast(value)
      new(value)
    end

    def ==(other)
      other.foo == foo
    end
  end

  property :days_of_month, Set
  property :custom_data, MyCustomType
end
