
class Widget
  include Ripple::Document
  property :size, Integer
  property :name, String, :default => "widget"
end