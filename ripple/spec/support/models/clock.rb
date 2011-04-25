

class Clock
  include Ripple::Document
  timestamps!
  many :modes
end

class Mode
  include Ripple::EmbeddedDocument
  timestamps!
end
