unless {}.respond_to? :stringify_keys
  class Hash
    def stringify_keys
      inject({}) do |hash, pair|
        hash[pair[0].to_s] = pair[1]
        hash
      end
    end
  end
end
