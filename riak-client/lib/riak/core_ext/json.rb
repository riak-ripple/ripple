unless Object.new.respond_to?(:to_json)
  # @private
  class Object
    def to_json(*args)
      Riak::JSON.encode(self)
    end
  end

  # @private
  class Symbol
    def to_json(*args)
      to_s.to_json(*args)
    end
  end
end
