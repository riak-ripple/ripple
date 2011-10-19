unless {}.respond_to? :symbolize_keys
  class Hash
    def symbolize_keys
      inject({}) do |hash, pair|
        hash[pair[0].to_sym] = pair[1]
        hash
      end
    end
  end
end
