
class Widget
  include Ripple::Document
  property :size, Integer
  property :name, String, :default => "widget"
end

class Cog < Widget
  property :name, String, :default => "cog"
end
