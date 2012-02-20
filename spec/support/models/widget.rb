class Widget
  include Ripple::Document
  property :size, Integer
  property :name, String, :default => "widget"
  property :manufactured, Boolean, :default => false
  property :shipped_at, Time
  property :restricted, Boolean, :default => false

  attr_protected :manufactured
  attr_protected :restricted, :as => :default

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
