
class Widget
  include Ripple::Document
  property :size, Integer
  property :name, String, :default => "widget"
  property :manufactured, Boolean, :default => false
  property :shipped_at, Time

  attr_protected :manufactured

  many :widget_parts
end

class Cog < Widget
  property :name, String, :default => "cog"
end

class WidgetPart
  include Ripple::Document
  property :name, String
  key_on :name
end
