require 'spec_helper'

describe Ripple::Document::Key do
  # require 'support/models/box'

  before do
    @box = Box.new
  end

  it "should define key getter and setter" do
    @box.should respond_to(:key)
    @box.should respond_to(:key=)
  end

  it "should stringify the assigned key" do
    @box.key = 2
    @box.key.should == "2"
  end

  it "should use a property as the key" do
    class ShapedBox < Box
      key_on :shape
    end
    @box = ShapedBox.new
    @box.key = "square"
    @box.key.should == "square"
    @box.shape.should == "square"
    @box.shape = "oblong"
    @box.key.should == "oblong"
  end
end
