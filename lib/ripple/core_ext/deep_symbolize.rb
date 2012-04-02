unless {}.respond_to?(:deep_symbolize_keys)
  class Hash
    def deep_symbolize_keys
      deep_dup.deep_symbolize_keys!      
    end
    
    def deep_symbolize_keys!
      keys.each do |key|
        value = delete(key)
        value = value.deep_symbolize_keys! if Hash === value
        self[(key.to_sym rescue key) || key] = value
      end
      self
    end
  end
end
