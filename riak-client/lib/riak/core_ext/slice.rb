unless {}.respond_to? :slice
  class Hash
    def slice(*keys)
      allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      hash = {}
      allowed.each { |k| hash[k] = self[k] if has_key?(k) }
      hash
    end

    def slice!(*keys)
      keys = keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
      omit = slice(*self.keys - keys)
      hash = slice(*keys)
      replace(hash)
      omit
    end
  end
end
