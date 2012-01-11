require 'ripple'

module Ripple
  # Makes IRB and other inspect output a bit friendlier
  module Inspection

    # A human-readable version of the {Ripple::Document} or {Ripple::EmbeddedDocument}
    # plus attributes
    def inspect
      attribute_list = attributes_for_persistence.except("_type").map {|k,v| "#{k}=#{v.inspect}" }.join(' ')
      inspection_string(attribute_list)
    end

    # A string representation of the {Ripple::Document} or {Ripple::EmbeddedDocument}
    def to_s
      inspection_string
    end

    private

    def inspection_string(extra = nil)
      body = self.class.name + persistance_identifier
      body += " #{extra}" if extra
      "<#{body}>"
    end

    def persistance_identifier
      self.class.embeddable? ? "" : ":#{key || '[new]'}"
    end

  end
end
