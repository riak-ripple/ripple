unless respond_to?(:define_singleton_method)
  class Object
    def define_singleton_method(name, &block)
      singleton_class = class << self; self; end
      singleton_class.send(:define_method, name, &block)
    end
  end
end
