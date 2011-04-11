require 'set'

unless Object.new.respond_to? :blank?
  class Object
    def blank?
      false
    end
  end

  class NilClass
    def blank?
      true
    end
  end

  class FalseClass
    def blank?
      true
    end
  end

  class TrueClass
    def blank?
      false
    end
  end

  class Set
    alias :blank? :empty?
  end

  class String
    def blank?
      self !~ /[^\s]/
    end
  end

  class Array
    alias :blank? :empty?
  end

  class Hash
    alias :blank? :empty?
  end
end

unless Object.new.respond_to? :present?
  class Object
    def present?
      !blank?
    end
  end
end
