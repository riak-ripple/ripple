require 'ripple'

module Ripple
  # Makes IRB and other inspect output a bit friendlier
  module Inspection
    # A human-readable version of the {Ripple::Document} or {Ripple::EmbeddedDocument}
    def inspect
      attribute_list = attributes_for_persistence.except("_type").map {|k,v| "#{k}=#{v.inspect}" }.join(' ')
      identifier = self.class.embeddable? ? "" : ":#{key || '[new]'}"
      "<#{self.class.name}#{identifier} #{attribute_list}>"
    end
  end
end
