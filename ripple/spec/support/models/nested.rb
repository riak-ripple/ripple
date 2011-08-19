module Nested
  module Scope
    class Parent
      include Ripple::Document
    end

    class Child
      include Ripple::EmbeddedDocument
      embedded_in :parent
    end
  end
end
